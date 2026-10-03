"""Generate truthful English metadata and screenshot briefs from shipped content."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DESCRIPTION='''BUILD. MERGE. SURVIVE.

The machines have taken over. A few scrappy robots have other plans.

Assemble your Scrap Squad, head into the wasteland, collect components and turn salvaged weapons into unexpected inventions.

MERGE WEAPONS
Combine blasters, elemental cores and strange modules. Discover recipes, equip your creations and take a new build into battle.

BUILD YOUR SCRAP SQUAD
Meet eight original robots, from cheerful BOLT to the repair specialist PATCH. Upgrade their circuitry and match weapon elements to squad affinities.

SURVIVE THE SWARM
Move to dodge attacks while your squad fires automatically. Choose temporary upgrades, break boss armor and use elemental weaknesses to your advantage.

DISCOVER BLUEPRINTS
Experiment with {count} discoverable recipes. Follow clues in the Blueprint Lab and expand your collection.

REBUILD SCRAP CITY
Construct facilities, improve research and increase your squad capacity. Build an Expedition Dock to collect eligible offline salvage for up to eight hours.

TRY A DIFFERENT CHALLENGE
Play Campaign, Survival, Boss Rush, Scrap Run, Fusion Lab, Daily Anomaly or Arena. Complete daily and weekly tasks without streak penalties.

Keep building. Keep experimenting. See how far your inventions take you.'''

def main():
    content=json.loads((ROOT/'Sources/ScrapCore/Resources/content.json').read_text())
    count=len(content['recipes'])
    metadata=dict(status='draft-not-for-upload-before-device-QA',locale='en-GB',name='Scrap Squad: Merge & Survive',
        subtitle='Idle Robot RPG & Merge Game',keywords='weapons,crafting,roguelite,offline,upgrade,action,swarm,robots,blueprints,boss,battle',
        promotionalText='Build it. Merge it. Survive the swarm. Experiment with weapon recipes, assemble your robot squad and rebuild Scrap City.',description=DESCRIPTION.format(count=count))
    for field,limit in [('name',30),('subtitle',30),('keywords',100),('promotionalText',170),('description',4000)]:
        if len(metadata[field])>limit: raise ValueError(f'{field} exceeds {limit} characters')
    shots=[
        ('MERGE. FIGHT. SURVIVE.','Build your robot squad.','Capture an actual mission with the available squad capacity and real active weapon effects. Do not depict a huge army that the build does not support.'),
        ('MERGE WEAPONS','Discover new combinations.','Capture the Workshop with a valid recipe and owned ingredients, then an actual reveal.'),
        (f'DISCOVER {count} BLUEPRINTS','Experiment. Combine. Discover.','Capture the Blueprint Database with the actual discovered/total counter. Never substitute 180+.'),
        ('BUILD YOUR ROBOT SQUAD','Meet heroes with distinct abilities.','Capture the eight-robot collection and a real equipped squad with affinity information.'),
        ('BREAK THE BOSS','Find its weakness. Build your counter.','Capture a live boss telegraph and armor bar; keep player and warnings readable.'),
        ('REBUILD SCRAP CITY','Turn salvage into a stronghold.','Capture an actual before/after city-building upgrade with visible level changes.')]
    package=dict(metadata=metadata,screenshots=[dict(order=i+1,headline=h,supportingCopy=s,realCaptureRequired=brief) for i,(h,s,brief) in enumerate(shots)],
        localizationStatus={code:'requires market research, translation and human review' for code in ['es','fr','de','it','pt','pt-BR','ja','ko','zh-Hans','zh-Hant']},
        policySources=['https://developer.apple.com/app-store/product-page/','https://developer.apple.com/app-store/review/guidelines/','https://developer.apple.com/app-store/asset-best-practices/'])
    out=ROOT/'Docs/Store/en-GB-draft.json'; out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(package,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Metadata limits passed. Generated six real-capture briefs using {count} shipped recipes. Keyword demand is not validated.')
if __name__=='__main__': main()
