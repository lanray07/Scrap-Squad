"""Generate localized storefront drafts and the ten-screen campaign manifest."""
import json
from pathlib import Path
from store_metadata import DESCRIPTION
ROOT=Path(__file__).resolve().parents[1]
# Editorial drafts; publication requires native-speaker review.
MARKETS={
'en-GB':('Merge & Survive','Robot battles & weapon fusion','crafting,roguelite,offline,upgrade,action,swarm,blueprint,boss,city,element,laser',
 'Merge weapons, build your robot squad and survive the swarm.',
 'Turn scrap into your next great invention in Scrap Squad, a robot action game about weapon fusion, squad building and survival.',None),
'es-ES':('Fusiona y sobrevive','Robots, armas y supervivencia','fabricación,acción,mejoras,jefes,planos,ciudad,elementos,láser,aventura',
 'Fusiona armas, forma tu escuadrón de robots y sobrevive a las oleadas.',
 'Convierte la chatarra en tu próxima gran invención en Scrap Squad, un juego de acción con robots, fusión de armas y supervivencia.',
 'Descubre {count} recetas de fusión y colecciona ocho robots originales. Esquiva ataques mientras tu escuadrón dispara automáticamente, elige mejoras y explota las debilidades de los jefes. Reconstruye Scrap City con nueve instalaciones. Construye el muelle de expediciones para recoger hasta ocho horas de recursos sin conexión. Explora siete modos, sigue pistas de planos y completa tareas diarias y semanales sin penalizaciones por perder una racha.'),
'fr-FR':('Fusion et survie','Robots et fusion d’armes','fabrication,action,boss,plans,ville,éléments,laser,amélioration,aventure',
 'Fusionnez vos armes, assemblez votre escouade de robots et survivez aux vagues.',
 'Transformez la ferraille en inventions dans Scrap Squad, un jeu d’action mêlant robots, fusion d’armes et survie.',
 'Découvrez {count} recettes de fusion et collectionnez huit robots originaux. Esquivez les attaques pendant que votre escouade tire automatiquement, choisissez des améliorations et exploitez les faiblesses des boss. Reconstruisez Scrap City avec neuf installations. Le quai d’expédition permet de récupérer jusqu’à huit heures de ressources hors ligne. Explorez sept modes, suivez les indices des plans et accomplissez des missions quotidiennes et hebdomadaires sans pénalité de série.'),
'de-DE':('Fusion & Überleben','Roboter und Waffenfusion','herstellen,action,boss,bauplan,stadt,element,laser,verbessern,abenteuer',
 'Fusioniere Waffen, baue dein Roboterteam und überlebe die Angriffswellen.',
 'Mach aus Schrott neue Erfindungen in Scrap Squad, einem Actionspiel mit Robotern, Waffenfusion und Überlebenskämpfen.',
 'Entdecke {count} Fusionsrezepte und sammle acht originelle Roboter. Weiche Angriffen aus, während dein Team automatisch feuert. Wähle Verbesserungen und nutze die Schwächen der Bosse. Baue Scrap City mit neun Einrichtungen wieder auf. Das Expeditionsdock ermöglicht bis zu acht Stunden Offline-Ressourcen. Erkunde sieben Modi, folge Bauplanhinweisen und erledige tägliche und wöchentliche Aufgaben ohne Strafen für unterbrochene Serien.'),
'it':('Fondi e sopravvivi','Robot e fusione di armi','creazione,azione,boss,progetti,città,elementi,laser,potenziamenti,avventura',
 'Fondi le armi, crea la tua squadra di robot e sopravvivi alle ondate.',
 'Trasforma i rottami in nuove invenzioni con Scrap Squad, un gioco d’azione con robot, fusione di armi e sopravvivenza.',
 'Scopri {count} ricette di fusione e colleziona otto robot originali. Schiva gli attacchi mentre la squadra spara automaticamente, scegli potenziamenti e sfrutta le debolezze dei boss. Ricostruisci Scrap City con nove strutture. Il molo delle spedizioni permette di raccogliere fino a otto ore di risorse offline. Esplora sette modalità, segui gli indizi dei progetti e completa missioni giornaliere e settimanali senza penalità per le serie interrotte.'),
'pt-PT':('Fusão e sobrevivência','Robôs e fusão de armas','criação,ação,chefes,projetos,cidade,elementos,laser,melhorias,aventura',
 'Funde armas, cria a tua equipa de robôs e sobrevive às vagas.',
 'Transforma sucata em novas invenções em Scrap Squad, um jogo de ação com robôs, fusão de armas e sobrevivência.',
 'Descobre {count} receitas de fusão e coleciona oito robôs originais. Desvia-te dos ataques enquanto a equipa dispara automaticamente, escolhe melhorias e explora as fraquezas dos chefes. Reconstrói Scrap City com nove instalações. O cais de expedições permite recolher até oito horas de recursos offline. Explora sete modos, segue pistas de projetos e completa tarefas diárias e semanais sem penalizações por séries interrompidas.'),
'pt-BR':('Fusão e sobrevivência','Robôs e fusão de armas','criação,ação,chefes,projetos,cidade,elementos,laser,melhorias,aventura',
 'Funda armas, monte seu esquadrão de robôs e sobreviva às ondas.',
 'Transforme sucata em novas invenções em Scrap Squad, um jogo de ação com robôs, fusão de armas e sobrevivência.',
 'Descubra {count} receitas de fusão e colecione oito robôs originais. Desvie dos ataques enquanto o esquadrão dispara automaticamente, escolha melhorias e explore as fraquezas dos chefes. Reconstrua Scrap City com nove instalações. O cais de expedições permite coletar até oito horas de recursos offline. Explore sete modos, siga pistas de projetos e complete tarefas diárias e semanais sem penalidades por sequências interrompidas.'),
'ja':('合成とサバイバル','ロボット部隊と武器合成','クラフト,アクション,強化,ボス,設計図,街づくり,属性,レーザー,冒険',
 '武器を合成し、ロボット部隊を編成。押し寄せる敵を乗り越えよう。',
 'Scrap Squadでスクラップを新しい発明に。武器合成とロボット部隊づくりを楽しむサバイバルアクション。',
 '{count}種類の合成レシピを発見し、個性豊かな8体のロボットを集めよう。部隊は自動で攻撃。敵の攻撃をかわし、強化を選び、ボスの弱点を狙おう。9つの施設でScrap Cityを再建。遠征ドックを建設すると、オフライン資源を最大8時間分回収できます。7つのモードに挑戦し、設計図のヒントを追い、毎日と毎週の任務に取り組もう。連続プレイが途切れてもペナルティはありません。'),
'ko':('합성과 생존','로봇 분대와 무기 합성','제작,액션,강화,보스,설계도,도시건설,속성,레이저,모험',
 '무기를 합성하고 로봇 분대를 꾸려 밀려오는 적을 상대하세요.',
 'Scrap Squad에서 고철을 새로운 발명품으로 바꾸세요. 무기 합성과 로봇 분대 육성이 만나는 생존 액션 게임입니다.',
 '{count}개의 합성법을 발견하고 개성 있는 로봇 8종을 수집하세요. 분대가 자동으로 공격하는 동안 적의 공격을 피하고 강화를 선택하며 보스의 약점을 공략하세요. 시설 9종으로 Scrap City를 재건하세요. 원정 부두를 건설하면 오프라인 자원을 최대 8시간분 수집할 수 있습니다. 7가지 모드를 탐험하고 설계도 단서를 따라 일일 및 주간 과제를 완료하세요. 연속 플레이가 끊겨도 불이익은 없습니다.'),
'zh-Hans':('合成与生存','机器人小队与武器合成','制作,动作,升级,首领,蓝图,城市建设,元素,激光,冒险',
 '合成武器，组建机器人小队，迎战蜂拥而至的敌人。',
 '在Scrap Squad中把废料变成新发明，体验融合武器合成、机器人养成与生存战斗的动作游戏。',
 '发现{count}种合成配方，收集8位原创机器人。小队会自动攻击，你需要躲避来袭攻击、选择强化并针对首领弱点制定策略。通过9种设施重建Scrap City。建造远征码头后，可领取最多8小时的离线资源。探索7种模式，追寻蓝图线索，完成每日与每周任务。连续游玩中断也不会受到惩罚。'),
'zh-Hant':('合成與生存','機器人小隊與武器合成','製作,動作,升級,首領,藍圖,城市建設,元素,雷射,冒險',
 '合成武器，組建機器人小隊，迎戰蜂擁而至的敵人。',
 '在Scrap Squad中把廢料變成新發明，體驗結合武器合成、機器人養成與生存戰鬥的動作遊戲。',
 '發現{count}種合成配方，收集8位原創機器人。小隊會自動攻擊，你需要閃避來襲攻擊、選擇強化並針對首領弱點制定策略。透過9種設施重建Scrap City。建造遠征碼頭後，可領取最多8小時的離線資源。探索7種模式，追尋藍圖線索，完成每日與每週任務。連續遊玩中斷也不會受到懲罰。'),
}
SHOTS=[
 ('11-boss',['DODGE THE BOSS.','BREAK ITS ARMOR.'],'Read the warning. Make your next move.','ROBOT BOSS BATTLES'),
 ('05-workshop',['SCRAP INTO','FIREPOWER.'],'Combine weapons. Discover your next build.','WEAPON FUSION'),
 ('03-squad',['SMALL BOTS.','BIG ATTITUDE.'],'Collect eight robots with distinct abilities.','SQUAD BUILDING'),
 ('07-fusion',['MEET YOUR','NEXT INVENTION.'],'Fuse a Flame Blaster. Equip the discovery.','MERGE WEAPONS'),
 ('04-blueprints',['12 BLUEPRINTS.','ONE CURIOUS MIND.'],'Follow clues. Experiment with combinations.','CRAFTING & DISCOVERY'),
 ('02-city',['BUILD A CITY','FROM SCRAP.'],'Construct facilities. Strengthen your squad.','CITY PROGRESSION'),
 ('12-daily',['ONE DAILY CODE.','YOUR NEXT BUILD.'],'Replay an offline challenge. Share the code.','DAILY ROGUELITE CHALLENGES'),
 ('13-overdrive',['EARN THE CHARGE.','UNLEASH OVERDRIVE.'],'Build your combo. Activate a power burst.','ACTION & COMBOS'),
 ('14-mastery',['MAKE YOUR MARK.','MASTER THE SCRAP.'],'Track medals, synergies and personal bests.','ROBOT MASTERY'),
 ('15-share',['GREAT RUN?','SHARE THE STORY.'],'Preview your card. Share when you choose.','CHALLENGE REPLAY & SHARING')]

def main():
    content=json.loads((ROOT/'Sources/ScrapCore/Resources/content.json').read_text())
    count=len(content['recipes']); out=ROOT/'Docs/Store'; out.mkdir(parents=True,exist_ok=True)
    for locale,(suffix,subtitle,keywords,promo,intro,detail) in MARKETS.items():
        title='Scrap Squad: '+suffix
        if len(title)>30: title='Scrap Squad'
        metadata=dict(locale=locale,name=title,subtitle=subtitle,keywords=keywords,promotionalText=promo,description=intro+'\n\n'+(detail.format(count=count) if detail else DESCRIPTION.format(count=count)))
        for field,limit in [('name',30),('subtitle',30),('keywords',100),('promotionalText',170),('description',4000)]:
            if len(metadata[field])>limit: raise ValueError(f'{locale}: {field} exceeds {limit}')
        if len(keywords.split(','))!=len(set(keywords.split(','))): raise ValueError('Duplicate keywords')
        package=dict(status='editorial-draft-requires-native-language-and-device-review',metadata=metadata,
          webSEO=dict(title=title+' | '+subtitle,metaDescription=intro[:155],h1=title,language=locale),
          review=dict(approved=False,keywordDemandValidated=False,appUILocalized=False),
          policySources=['https://developer.apple.com/app-store/product-page/','https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications'])
        if locale=='en-GB': package['screenshots']=[dict(order=i+1,capture='Store-'+capture,headline=lines,supportingCopy=copy,keyword=keyword) for i,(capture,lines,copy,keyword) in enumerate(SHOTS)]
        (out/f'{locale}-draft.json').write_text(json.dumps(package,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        (out/f'{locale}-description.txt').write_text(metadata['description']+'\n',encoding='utf-8')
    print(f'{len(MARKETS)} storefront drafts passed field limits; ten screenshot briefs; {count} actual recipes.')
if __name__=='__main__': main()
