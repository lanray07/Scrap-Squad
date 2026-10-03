"""Deterministic content authoring. Run after editing; never calls a network service."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
strings = {}
def text(key, value):
    strings[key] = value
    return key

weapons = []
def weapon(id, name, description, element, rarity, damage, interval, projectiles=1, **mods):
    weapons.append(dict(id=id, nameKey=text('weapon.'+id, name), descriptionKey=text('weapon.'+id+'.description', description),
        element=element, rarity=rarity, damage=damage, interval=interval, projectiles=projectiles,
        modifiers=[dict(kind=k, value=v) for k,v in mods.items()]))

weapon('blaster','Basic Blaster','A salvaged rivet driver. Small beginnings, big intentions.','ballistic','common',18,.65)
weapon('shotgun','Scrap Shotgun','Three bolts, one very loud opinion.','ballistic','common',14,.95,3)
weapon('rocket','Rocket Launcher','Recycled fuel. Unrecycled enthusiasm.','explosive','uncommon',38,1.4,explosion=.08)
weapon('laser','Workshop Laser','A cutting tool with a new job.','energy','uncommon',24,.5)
weapon('flame','Flame Blaster','Hot rivets leave a persistent burn.','fire','uncommon',24,.6,burn=1)
weapon('fireDrone','Fire Drone','A tiny flying furnace follows your lead.','drone','rare',29,.55,2,burn=1)
weapon('arc','Arc Blaster','Electric bolts jump between nearby machines.','electric','uncommon',23,.6,chain=1)
weapon('chain','Chain Cannon','A branching current finds every loose screw.','electric','rare',28,.55,chain=3)
weapon('frost','Frost Shotgun','A cold front made from industrial coolant.','cryo','uncommon',18,.8,3,freeze=1)
weapon('blizzard','Blizzard Cannon','Frozen shells burst into a cloud of shrapnel.','cryo','epic',35,.8,3,freeze=1,explosion=.1)
weapon('swarm','Missile Swarm','A flock of guided rockets with terrible manners.','drone','epic',32,.65,4,explosion=.06)
weapon('prism','Prism Laser','Split light ricochets through the swarm.','energy','rare',30,.45,3)
weapon('plasma','Plasma Storm','An unstable electric furnace bends the air.','electric','legendary',48,.45,3,chain=2,burn=1)
weapon('orbital','Orbital Hammer','Rebuilt satellites rain down precision fire.','explosive','legendary',95,1.1,2,explosion=.16)
weapon('aurora','Aurora Engine','Cold light fractures into a dazzling storm.','cryo','mythic',58,.4,4,freeze=1,chain=2)
weapon('singularity','Singularity Array','An impossible invention. Please stand back.','energy','mythic',72,.4,4,explosion=.14)

components = [dict(id=id,nameKey=text('component.'+id,name),element=element) for id,name,element in [
 ('fire','Fire Core','fire'),('tesla','Tesla Core','electric'),('cryo','Cryo Core','cryo'),('drone','Drone Core','drone'),
 ('splitter','Splitter Module','experimental'),('explosive','Explosive Payload','explosive'),('ricochet','Ricochet Chip','energy')]]
recipes = []
for a,b,c,cost,clue in [
 ('blaster','fire','flame',70,'Give a humble blaster a warmer heart.'),
 ('flame','drone','fireDrone',110,'Let the furnace take flight.'),
 ('blaster','tesla','arc',70,'Some rivets carry a charge.'),
 ('arc','splitter','chain',120,'One current can become many.'),
 ('shotgun','cryo','frost',80,'Cool down a scatter of scrap.'),
 ('frost','explosive','blizzard',160,'A cold front needs a big entrance.'),
 ('rocket','drone','swarm',160,'Teach rockets to fly together.'),
 ('laser','ricochet','prism',120,'Light can take the scenic route.'),
 ('chain','fire','plasma',260,'Heat an electrical storm.'),
 ('swarm','explosive','orbital',300,'A bigger payload needs a higher perch.'),
 ('blizzard','tesla','aurora',450,'Charge a winter storm.'),
 ('prism','splitter','singularity',450,'Split a beam until reality gives way.')]:
    recipes.append(dict(id=c,weapon=a,component=b,result=c,scrapCost=cost,clueKey=text('clue.'+c,clue)))

robots=[]
for id,name,personality,passive,active,rarity,hp,dmg,speed,affinity,cost,silhouette,color in [
 ('bolt','BOLT','Optimistic to the last rivet.','Balanced circuitry: +8% damage.','Pulse burst: damages nearby enemies.','common',100,.08,0,'ballistic',0,'round','F5B942'),
 ('tank','TANK','Big shoulders. Soft heart.','Heavy chassis: a larger health pool.','Fortify: immune to damage for 5 seconds.','rare',170,.12,-.05,'ballistic',700,'heavy','809CAA'),
 ('zip','ZIP','Already there. Already bored.','Fast servos: +20% attack speed.','Flash burst: pulse damage and an immediate next shot.','uncommon',70,0,.2,'electric',450,'slim','66DBB4'),
 ('patch','PATCH','Everything deserves a second chance.','Repair field: regenerate 0.6 health per second.','Repair pulse: restore 35% squad health.','uncommon',85,.02,0,'drone',300,'medic','F48193'),
 ('nova','NOVA','Quiet until the lights go out.','Precision optics: +18% damage.','Solar pulse: damages nearby enemies.','epic',90,.18,.05,'energy',1100,'orb','A9A0FF'),
 ('boomer','BOOMER','Safety third. Friendship first.','Payload expert: adds splash damage.','Demolition: a powerful area blast.','rare',110,.1,0,'explosive',850,'heavy','F28C50'),
 ('glitch','GLITCH','Speaks fluent error code.','Corrupted clock: +10% attack speed.','Scramble: damages and slows nearby enemies.','epic',80,.08,.1,'electric',1200,'slim','64D5EB'),
 ('magnet','MAGNET','One robot’s trash is their treasure.','Collector: +10% damage.','Salvage pulse: area damage and a small repair.','rare',95,.1,0,'experimental',900,'round','A5C96B')]:
    robots.append(dict(id=id,nameKey=text('robot.'+id,name),personalityKey=text('robot.'+id+'.personality',personality),
        passiveKey=text('robot.'+id+'.passive',passive),activeKey=text('robot.'+id+'.active',active),rarity=rarity,
        health=hp,damageBonus=dmg,speedBonus=speed,affinity=affinity,unlockCost=cost,silhouette=silhouette,color=color))
buildings=[]
for id,name,desc,cost,symbol in [
 ('workshop','Workshop','Build and fuse weapons from salvaged components.',100,'wrench.and.screwdriver.fill'),
 ('research','Research Lab','Each level gives your squad +5% damage.',180,'atom'),
 ('factory','Robot Factory','Rebuild a home for rescued robots.',150,'gearshape.2.fill'),
 ('dock','Expedition Dock','Each level earns 2 scrap and 4 credits per offline minute.',120,'paperplane.fill'),
 ('blueprints','Blueprint Lab','Keep a record of your discoveries.',100,'square.stack.3d.up.fill'),
 ('arena','Arena','A home for score challenges.',220,'flag.checkered'),
 ('portal','Portal','Study the daily anomaly.',250,'sparkles'),
 ('market','Market','A gathering place for city traders.',160,'bag.fill'),
 ('command','Command Center','Every two levels unlock another squad slot.',200,'antenna.radiowaves.left.and.right')]:
    buildings.append(dict(id=id,nameKey=text('building.'+id,name),descriptionKey=text('building.'+id+'.description',desc),baseCost=cost,symbol=symbol,maxLevel=10))
biomes=[]
for index,(id,name,boss,weakness,palette,hazard,enemies) in enumerate([
 ('rust','Rust Flats','The Scrap Titan','electric',['162C35','D29B50','F5B942'],'scrapfall',['swarmer','tank','exploder']),
 ('neon','Neon Junkyard','Iron Maw','cryo',['20243E','D56EA5','6DE0DA'],'surge',['swarmer','ranged','shield','flying']),
 ('frozen','Frozen Foundry','The Harvester','fire',['193640','8FC4D4','C2EAF2'],'frost',['tank','repair','ranged']),
 ('toxic','Toxic Processing Plant','Void Engine','energy',['243832','8EA552','B5DF61'],'leak',['exploder','shield','repair','burrower']),
 ('city','Abandoned Megacity','Junk Queen','explosive',['252B3F','9F91B6','E4A0AB'],'scrapfall',['ranged','tank','swarmer']),
 ('electric','Electric Wastes','Omega Warden','cryo',['1C2941','8790DC','63DEEC'],'surge',['shield','ranged','exploder']),
 ('graveyard','Machine Graveyard','The Assembler','electric',['292E32','A99983','E9C997'],'scrapfall',['repair','tank','exploder','elite']),
 ('orbital','Orbital Factory','Orbital Custodian','explosive',['192E40','6BA7C0','AEDDE4'],'surge',['shield','ranged','repair']),
 ('rift','Quantum Rift','The Rift Heart','energy',['29213D','AE82D1','DAB1FF'],'rift',['tank','ranged','exploder','miniboss'])]):
    biomes.append(dict(id=id,nameKey=text('biome.'+id,name),bossKey=text('boss.'+id,boss),weakness=weakness,palette=palette,
        difficulty=round(1+index*.28,2),hazard=hazard,enemies=enemies))
upgrades=[]
for id,name,desc,element,kind,value,symbol in [
 ('tesla','Tesla Coil','Hit two additional targets each volley.','electric','chain',2,'bolt.fill'),
 ('fire','Fire Core','Shots burn enemies for three seconds.','fire','burn',1,'flame.fill'),
 ('cryo','Cryo Core','Shots slow enemies for two seconds.','cryo','freeze',1,'snowflake'),
 ('drone','Drone Core','Add an extra projectile to each volley.','drone','split',1,'paperplane.fill'),
 ('ricochet','Ricochet Chip','Increase damage by 25%.','energy','damage',.25,'arrow.triangle.branch'),
 ('splitter','Splitter Module','Add two projectiles to each volley.','experimental','split',2,'arrow.triangle.branch'),
 ('payload','Explosive Payload','Shots damage enemies near their target.','explosive','explosion',.08,'burst.fill'),
 ('plasma','Plasma Cell','Increase damage by 35%.','energy','damage',.35,'sun.max.fill'),
 ('critical','Critical Processor','Increase critical chance by 12%.','ballistic','critical',.12,'scope'),
 ('repair','Repair Nanites','Regenerate 1.8 health each second.','drone','repair',1.8,'cross.fill'),
 ('overclock','Overclock Module','Increase attack speed by 25%.','electric','speed',.25,'speedometer')]:
    upgrades.append(dict(id=id,nameKey=text('upgrade.'+id,name),descriptionKey=text('upgrade.'+id+'.description',desc),element=element,kind=kind,value=value,symbol=symbol))
content=dict(weapons=weapons,components=components,recipes=recipes,robots=robots,buildings=buildings,biomes=biomes,upgrades=upgrades,
    economy=dict(offlineCapHours=8,offlineScrapPerMinute=2,offlineCreditsPerMinute=4,robotLevelBaseCost=100,costGrowth=1.35,
        killScrap=5,bossCredits=250,runSeconds=120,bossAtSeconds=65,upgradeSeconds=[20,45,75],rebootZone=5))

ui={
 'app.name':'Scrap Squad','app.subtitle':'MERGE & SURVIVE','app.promise':'Build it. Merge it. Survive the swarm.',
 'nav.city':'City','nav.squad':'Squad','nav.battle':'Battle','nav.blueprints':'Blueprints','nav.shop':'Shop',
 'currency.scrap':'Scrap','currency.credits':'Credits','currency.cores':'Cores',
 'city.title':'Welcome to Scrap City','city.subtitle':'A little scrap. A lot of possibility.',
 'city.level':'City level','city.workshop':'Open Workshop','city.upgrade':'Build / Upgrade','city.level.label':'Level',
 'city.missions':'Commander’s orders','mission.daily':'Daily: defeat 60 machines','mission.weekly':'Weekly: defeat 3 bosses',
 'mission.claim':'Claim reward','mission.claimed':'Reward claimed','mission.note':'New tasks arrive without streak penalties.',
 'squad.title':'Your misfit heroes','squad.subtitle':'Different parts. One purpose.','squad.add':'Add to squad','squad.remove':'Remove from squad',
 'squad.unlock':'Rescue robot','squad.upgrade':'Upgrade robot','squad.passive':'Passive circuitry','squad.active':'Commander ability',
 'squad.affinity':'Affinity synergy: +15% weapon damage','squad.commander':'The first robot in your squad leads its active ability.',
 'battle.title':'Into the wasteland','battle.subtitle':'The swarm is waiting. Bring something ridiculous.',
 'battle.deploy':'Deploy squad','battle.weapon':'Equipped weapon','battle.mode':'Mission mode','battle.zone':'Select zone',
 'battle.move':'Drag anywhere in the arena to move','battle.ability':'Ability','battle.retreat':'Retreat','battle.pause':'Pause',
 'battle.resume':'Resume','battle.paused':'Mission paused','battle.choose':'Choose your upgrade','battle.choice.subtitle':'Make this invention your own.',
 'battle.armor':'Breakable armor','battle.armor.broken':'Armor destroyed: full damage unlocked',
 'battle.health':'Squad integrity','battle.kills':'Machines defeated','battle.score':'Score','battle.boss':'Boss incoming',
 'battle.victory':'Swarm survived','battle.defeat':'Back to the drawing board','battle.results':'Every expedition brings progress.',
 'battle.return':'Return to city','battle.priority':'Target priority','battle.weakness':'Weakness','battle.daily':'Today’s boosted element',
 'battle.survival.note':'Survival and Arena continue until defeat or retreat. Other modes last two minutes; Boss Rush ends after three bosses.',
 'priority.nearest':'Nearest','priority.weakest':'Weakest','priority.boss':'Boss first',
 'mode.campaign':'Campaign','mode.survival':'Survival','mode.bossRush':'Boss Rush','mode.scrapRun':'Scrap Run','mode.fusionLab':'Fusion Lab','mode.dailyAnomaly':'Daily Anomaly','mode.arena':'Arena',
 'lab.title':'Invent something outrageous','lab.subtitle':'Every great idea starts with two questionable parts.',
 'lab.recipes':'Workshop','lab.database':'Blueprint database','lab.roulette':'Fusion Roulette','lab.fuse':'Fuse weapon','lab.equip':'Equip',
 'lab.upgrade':'Upgrade weapon','lab.unknown':'Undiscovered invention','lab.discovered':'Discovered','lab.reveal':'New weapon discovered',
 'lab.initiated':'Fusion initiated…','lab.share':'Share invention','lab.roulette.note':'Two different weapons + one Mystery Core. Each listed result has an equal chance. No purchase required.',
 'lab.weaponA':'Weapon A','lab.weaponB':'Weapon B','lab.spin':'Start fusion','lab.inventory':'Your arsenal','lab.components':'Components',
 'shop.title':'Make it yours','shop.subtitle':'The core adventure is free. No mandatory ads.',
 'shop.unavailable':'The store is not configured for this development build. No purchases can be made.',
 'shop.restore':'Restore purchases','shop.refresh':'Load store','shop.pending':'Purchase is awaiting approval.','shop.restored':'Purchases restored.',
 'shop.verified':'Purchase verified.','shop.entitlements':'Owned cosmetics','shop.note':'Only verified cosmetic entitlements are supported in this build. Consumables and subscriptions are not offered.',
 'settings.title':'Your controls','settings.haptics':'Haptic feedback','settings.motion':'Reduce motion','settings.flashes':'Reduce flashes',
 'settings.shake':'Screen shake','settings.numbers':'Damage numbers','settings.particles':'Particle intensity','settings.master':'Master volume',
 'settings.music':'Music volume','settings.sfx':'Sound effects','settings.language':'Language','settings.system':'Follow device language',
 'settings.gamecenter':'Connect Game Center','settings.leaderboards':'Leaderboards','settings.reboot':'Core Reboot',
 'settings.reboot.detail':'Resets zone, city buildings, robot levels, credits and scrap. Keeps robots, squad capacity, squad, weapons, weapon levels, components, cores, blueprints, achievements and preferences. Each reboot permanently adds 10% damage. Unlock at zone 6.',
 'settings.reboot.confirm':'Reboot city','settings.save.error':'Your progress could not be saved. Check device storage and retry before closing the app.',
 'offline.title':'Welcome back, commander','offline.description':'Your expedition brought back real salvage. Rewards accumulate for up to eight hours.',
 'offline.claim':'Claim salvage','offline.away':'Expedition duration',
 'common.done':'Done','common.cancel':'Cancel','common.ok':'OK','common.error':'Cannot complete action','common.locked':'Locked','common.max':'Maximum level',
 'error.insufficientFunds':'You need more resources for this upgrade.','error.missingIngredient':'You are missing a weapon or component.',
 'error.locked':'This action has not been unlocked yet.','error.invalidSelection':'Choose a valid squad or pair of different weapons.',
 'error.maxLevel':'This upgrade is already at its maximum level.','error.invalidContent':'The game content could not be loaded.',
 'error.purchase':'The purchase could not be verified or completed. Please try again.','error.load':'Saved progress could not be read. The original save is preserved; new progress cannot be saved.',
 'accessibility.settings':'Open settings','accessibility.robot':'Robot portrait','accessibility.arena':'Combat arena. Drag to move. Automatic weapons target nearby enemies.',
 'tutorial.title':'A squad worth rebuilding','tutorial.body':'Drag in battle to dodge attacks. Your squad fires automatically. Choose upgrades, bring home scrap, and combine weapons with cores in the Workshop. Build the Expedition Dock to earn salvage while away.',
 'tutorial.start':'Let’s build something','achievement.firstfusion':'First Fusion','achievement.madscientist':'Mad Scientist',
 'achievement.scrapengineer':'Scrap Engineer','achievement.swarmbreaker':'Swarm Breaker','achievement.bossbreaker':'Boss Breaker','achievement.mythicengineer':'Mythic Engineer',
 'achievements.title':'Commander’s record','store.skin.bolt':'Sunset BOLT','store.skin.nova':'Starlight NOVA',
 'store.skin.bolt.description':'An optional warm coral paint finish for BOLT.','store.skin.nova.description':'An optional midnight blue paint finish for NOVA.'
}
strings.update(ui)
for value in ['common','uncommon','rare','epic','legendary','mythic']:
    strings['rarity.'+value]=value.capitalize()
for value in ['ballistic','fire','cryo','electric','energy','explosive','drone','experimental']:
    strings['element.'+value]=value.capitalize()

target=ROOT/'Sources/ScrapCore/Resources/content.json'
target.parent.mkdir(parents=True,exist_ok=True)
target.write_text(json.dumps(content,indent=2)+'\n',encoding='utf-8')
catalog=ROOT/'App/Resources/Localizable.xcstrings'
catalog.parent.mkdir(parents=True,exist_ok=True)
existing=json.loads(catalog.read_text(encoding='utf-8')) if catalog.exists() else {'sourceLanguage':'en','version':'1.0','strings':{}}
for key,value in strings.items():
    entry=existing['strings'].setdefault(key,{'extractionState':'manual','localizations':{}})
    old=entry['localizations'].get('en',{}).get('stringUnit',{}).get('value')
    if old is not None and old != value:
        for locale,localization in entry['localizations'].items():
            if locale != 'en' and 'stringUnit' in localization:
                localization['stringUnit']['state']='needs_review'
    entry['localizations']['en']={'stringUnit':{'state':'translated','value':value}}
catalog.write_text(json.dumps(existing,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Authored {len(weapons)} weapons, {len(recipes)} recipes, {len(robots)} robots, {len(strings)} source strings.')
