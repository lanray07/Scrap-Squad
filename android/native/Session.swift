import Foundation

#if ORIGINAL_CORE
@MainActor
#endif
final class Session {
    var content: GameContent?
    var profile = PlayerProfile(now: Date(timeIntervalSince1970: 0))
    var engine: BattleEngine?
    var claimed = false
    func request(_ input: String) -> String {
        do {
            guard let bytes = input.data(using: .utf8), let q = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else { throw GameError.invalidSelection }
            let op = q["op"] as? String ?? "state"
            let now = Date(timeIntervalSince1970: (q["now"] as? Double) ?? Date().timeIntervalSince1970)
            if op == "init" {
                engine = nil; claimed = false
                guard let text = q["content"] as? String else { throw GameError.invalidContent }
                let decoded = try JSONDecoder().decode(GameContent.self, from: Data(text.utf8)); try decoded.validate(); content = decoded
                if let text = q["profile"] as? String { profile = try JSONDecoder().decode(PlayerProfile.self, from: Data(text.utf8)); try profile.validate(content: decoded) }
                else { profile = PlayerProfile(now: now) }
            }
            guard let content else { throw GameError.invalidContent }
            let id = q["id"] as? String ?? ""
            switch op {
            case "deploy":
                guard engine == nil || engine!.state == .defeated || engine!.state == .victory else { throw GameError.invalidSelection }
                var snapshot = profile
                let zone = q["zone"] as? Int ?? profile.zone
                guard zone >= 0, zone <= profile.zone else { throw GameError.locked }
                snapshot.zone = zone
                let seed = UInt64(q["seed"] as? String ?? "42") ?? 42
                guard let mode = GameMode(rawValue: q["mode"] as? String ?? "campaign") else { throw GameError.invalidSelection }
                let code = q["challenge"] as? String
                if let code { guard let challenge = RunChallenge(code: code) else { throw GameError.invalidSelection }; snapshot = challenge.profile(content: content, preferences: profile.preferences) }
                engine = BattleEngine(content: content, profile: snapshot, mode: code == nil ? mode : .dailyAnomaly, seed: code.flatMap { RunChallenge(code: $0).map { UInt64($0.seed) } } ?? seed, challengeCode: code); claimed = false
            case "step":
                guard let engine else { throw GameError.invalidSelection }
                let dx = q["x"] as? Double ?? 0, dy = q["y"] as? Double ?? 0, dt = q["dt"] as? Double ?? 0
                guard dx.isFinite, dy.isFinite, dt.isFinite else { throw GameError.invalidSelection }
                engine.step(delta: dt, movement: Vector(dx, dy))
            case "choose": guard let engine, let choice = engine.choices.first(where: { $0.id == id }) else { throw GameError.invalidSelection }; engine.choose(choice)
            case "dash": _ = engine?.activateDash(direction: Vector(q["x"] as? Double ?? 0, q["y"] as? Double ?? 0))
            case "overdrive": _ = engine?.activateOverdrive()
            case "ability": engine?.activateAbility()
            case "priority": if let value = TargetPriority(rawValue: id) { engine?.priority = value }
            case "retreat": engine?.retreat()
            case "claim":
                guard let engine, engine.state == .victory || engine.state == .defeated else { throw GameError.invalidSelection }
                if !claimed { _ = Progression.apply(engine.reward(), profile: &profile, content: content, now: now); claimed = true }
            case "fuse": guard let recipe = content.recipes.first(where: { $0.id == id }) else { throw GameError.invalidSelection }; try Progression.fuse(recipe, profile: &profile)
            case "roulette":
                _ = try Progression.roulette(a: q["a"] as? String ?? "", b: q["b"] as? String ?? "", profile: &profile, content: content, randomIndex: q["index"] as? Int ?? 0)
            case "challenge": guard RunChallenge(code: id) != nil else { throw GameError.invalidSelection }
            case "building": guard let item = content.buildings.first(where: { $0.id == id }) else { throw GameError.invalidSelection }; try Progression.upgradeBuilding(item, profile: &profile, content: content, now: now)
            case "robot": guard let item = content.robots.first(where: { $0.id == id }) else { throw GameError.invalidSelection }; try Progression.upgradeRobot(item, profile: &profile, content: content)
            case "weapon": guard let item = content.weapons.first(where: { $0.id == id }) else { throw GameError.invalidSelection }; try Progression.upgradeWeapon(item, profile: &profile, content: content)
            case "squad": try Progression.toggleSquad(id, profile: &profile)
            case "equip": guard profile.weapons[id, default: 0] > 0 else { throw GameError.locked }; profile.equippedWeapon = id
            case "offline": _ = Progression.claimOffline(&profile, content: content, now: now)
            case "mission": try Progression.claimMission(weekly: q["weekly"] as? Bool ?? false, profile: &profile, now: now)
            case "reboot": try Progression.reboot(&profile, content: content)
            case "preferences":
                guard let value = q["value"] else { throw GameError.invalidSelection }
                let preferences = try JSONDecoder().decode(Preferences.self, from: JSONSerialization.data(withJSONObject: value))
                var candidate = profile; candidate.preferences = preferences; try candidate.validate(content: content); profile = candidate
            case "init", "state", "menu", "roulettePreview": break
            default: throw GameError.invalidSelection
            }
            if op != "step" { Progression.refreshMissions(&profile, now: now) }
            var result = try snapshot()
            if op == "menu" {
                let offline = Progression.offline(profile: profile, content: content, now: now)
                result["menu"] = [
                    "cityLevel": profile.cityLevel, "playerLevel": profile.playerLevel, "squadCapacity": profile.squadCapacity,
                    "dailyChallenge": RunChallenge.daily(now: now).code,
                    "offline": ["seconds": offline.seconds, "scrap": offline.scrap, "credits": offline.credits],
                    "buildingCosts": Dictionary(uniqueKeysWithValues: content.buildings.map { ($0.id, Progression.cost(base: $0.baseCost, level: profile.buildingLevels[$0.id, default: 0], economy: content.economy)) }),
                    "robotCosts": Dictionary(uniqueKeysWithValues: content.robots.map { ($0.id, profile.unlockedRobots.contains($0.id) ? Progression.cost(base: content.economy.robotLevelBaseCost, level: profile.robotLevels[$0.id, default: 1] - 1, economy: content.economy) : $0.unlockCost) }),
                    "weaponCosts": Dictionary(uniqueKeysWithValues: content.weapons.map { ($0.id, Progression.cost(base: 80, level: profile.weaponLevels[$0.id, default: 1] - 1, economy: content.economy)) }),
                    "achievements": Progression.achievements(profile, content: content),
                    "mastery": MasteryMilestone.allCases.map { ["key": $0.nameKey, "progress": $0.progress(profile), "goal": $0.goal] as [String: Any] },
                    "runMedals": Dictionary(uniqueKeysWithValues: (profile.journal?.recent ?? []).map { ($0.id.uuidString, $0.medals.map(\.nameKey)) })
                ] as [String: Any]
            }
            if op == "roulettePreview" { result["candidates"] = Progression.rouletteCandidates(a: q["a"] as? String ?? "", b: q["b"] as? String ?? "", content: content).map(\.id) }
            return try serialize(result)
        } catch { return (try? serialize(["error": String(describing: error)])) ?? "{\"error\":\"invalidContent\"}" }
    }
    func vector(_ value: Vector) -> [Double] { [value.x, value.y] }
    func area(_ value: AttackArea) -> [String: Any] { ["shape": String(describing: value.shape), "from": vector(value.from), "to": vector(value.to), "radius": value.radius, "thickness": value.thickness] }
    func snapshot() throws -> [String: Any] {
        var result: [String: Any] = ["profile": String(decoding: try JSONEncoder().encode(profile), as: UTF8.self)]
        guard let e = engine else { return result }
        result["battle"] = [
            "state": String(describing: e.state), "elapsed": e.elapsed, "wave": e.wave, "player": vector(e.player), "health": e.health, "maxHealth": e.maxHealth,
            "kills": e.kills, "bosses": e.bosses, "score": e.score, "zone": e.profile.zone, "squad": e.profile.squad, "weapon": e.weapon.id,
            "dashCooldown": e.dashCooldown, "dashRemaining": e.dashRemaining, "abilityCooldown": e.abilityCooldown,
            "combo": e.combo.count, "charge": e.combo.charge, "overdrive": e.combo.overdrive, "synergies": e.synergies.map(\.rawValue).sorted(),
            "evolution": e.evolution?.rawValue ?? "", "perfectDodges": e.perfectDodges, "completedWaveEvents": e.completedWaveEvents,
            "event": e.waveEvent?.kind.rawValue ?? "", "eventIDs": e.waveEvent?.enemyIDs.sorted() ?? [], "bonusScrap": e.bonusScrap,
            "choices": e.choices.map(\.id), "selected": e.selected,
            "enemies": e.enemies.map { ["id": $0.id, "kind": $0.kind, "position": vector($0.position), "health": $0.health, "maxHealth": $0.maxHealth, "armor": $0.armor] as [String: Any] },
            "projectiles": e.projectiles.map { ["id": $0.id, "position": vector($0.position), "target": $0.targetID] as [String: Any] },
            "warnings": e.warnings.map { ["id": $0.id, "area": area($0.area), "remaining": $0.remaining, "duration": $0.duration, "boss": $0.boss] as [String: Any] },
            "effects": e.effects.map { ["id": $0.id, "from": vector($0.from), "to": vector($0.to), "style": $0.style.rawValue, "damage": $0.damage, "critical": $0.critical, "remaining": $0.remaining] as [String: Any] },
            "drones": e.dronePositions.map(vector), "strikes": e.evolutionStrikes.map { ["area": area($0.area), "remaining": $0.remaining] as [String: Any] }
        ] as [String: Any]
        return result
    }
    func serialize(_ value: [String: Any]) throws -> String { String(decoding: try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]), as: UTF8.self) }
}

#if !ORIGINAL_CORE
// JNI owns a mutex around every call. Neither state nor Swift object references
// escape this boundary; Android never calls the engine concurrently.
private var session = Session()
@_cdecl("sq_request")
public func sqRequest(_ input: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? { strdup(session.request(String(cString: input))) }
@_cdecl("sq_free")
public func sqFree(_ pointer: UnsafeMutablePointer<CChar>?) { free(pointer) }
#endif
