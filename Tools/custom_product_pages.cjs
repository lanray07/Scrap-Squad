/* Reproducible localized campaign layout using genuine, unmodified UI captures.
 * NODE_PATH=<bundled node_modules> node Tools/custom_product_pages.cjs
 * Exports are local in Marketing/CustomProductPages; no network or publication.
 */
const fs=require('fs'),path=require('path'),crypto=require('crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),out=path.join(root,'Marketing/CustomProductPages');
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
// Editorial translations. Game UI remains English; no language-support claim.
// Per locale: fusion, survival, daily headlines; three promotional texts; language notice.
const copy={
'en-GB':[['Craft your','firepower.'],['Dodge. Adapt.','Survive.'],['One code.','Your best run.'],
'Fuse weapons, discover blueprints and equip your robot squad. Turn workshop experiments into your next combat build.',
'Read boss warnings, dodge attacks and choose upgrades. Lead your robot squad through endless waves and three-boss challenges.',
'Replay a Daily Circuit code, explore its loadout and share your result card. Compare runs with friends, without a live leaderboard.','Game interface in English.'],
'es-ES':[['Fabrica tu','potencia de fuego.'],['Esquiva. Mejora.','Sobrevive.'],['Un código.','Tu mejor partida.'],
'Fusiona armas, descubre planos y equipa a tu escuadrón de robots. Convierte tus experimentos del taller en nuevas opciones de combate.',
'Anticipa los ataques de los jefes, esquiva y elige mejoras. Guía a tus robots por oleadas sin fin y desafíos de tres jefes.',
'Repite un código del Circuito diario, explora su equipo y comparte tu tarjeta de resultados. Compara partidas sin clasificación en línea.','Interfaz del juego en inglés.'],
'fr-FR':[['Fabriquez votre','puissance de feu.'],['Esquivez. Évoluez.','Survivez.'],['Un code.','Votre meilleur run.'],
'Fusionnez des armes, découvrez des plans et équipez vos robots. Transformez vos expériences à l’atelier en nouvelles possibilités de combat.',
'Anticipez les attaques des boss, esquivez et choisissez vos améliorations. Affrontez des vagues infinies et des défis à trois boss.',
'Rejouez un code du Circuit quotidien, explorez son équipement et partagez votre fiche de résultats. Comparez vos runs sans classement en ligne.','Interface du jeu en anglais.'],
'de-DE':[['Baue deine','Feuerkraft.'],['Ausweichen. Lernen.','Überleben.'],['Ein Code.','Dein bester Lauf.'],
'Fusioniere Waffen, entdecke Baupläne und rüste dein Roboterteam aus. Mach aus Werkstatt-Experimenten neue Möglichkeiten für den Kampf.',
'Erkenne Bosswarnungen, weiche Angriffen aus und wähle Upgrades. Führe dein Team durch endlose Wellen und Herausforderungen mit drei Bossen.',
'Spiele einen Tagescode erneut, entdecke seine Ausrüstung und teile deine Ergebniskarte. Vergleiche Läufe ohne Online-Bestenliste.','Spieloberfläche auf Englisch.'],
'it':[['Crea la tua','potenza di fuoco.'],['Schiva. Adattati.','Sopravvivi.'],['Un codice.','La tua sfida.'],
'Fondi armi, scopri progetti ed equipaggia i tuoi robot. Trasforma gli esperimenti in officina in nuove possibilità di combattimento.',
'Anticipa gli attacchi dei boss, schiva e scegli potenziamenti. Guida i robot tra ondate infinite e sfide con tre boss.',
'Rigioca un codice del Circuito giornaliero, esplora il suo equipaggiamento e condividi i risultati. Confronta partite senza classifica online.','Interfaccia di gioco in inglese.'],
'pt-PT':[['Cria o teu','poder de fogo.'],['Desvia. Adapta.','Sobrevive.'],['Um código.','A tua melhor ronda.'],
'Funde armas, descobre projetos e equipa os teus robôs. Transforma experiências na oficina em novas opções para o combate.',
'Antecipa ataques dos chefes, desvia-te e escolhe melhorias. Guia os teus robôs por vagas sem fim e desafios com três chefes.',
'Repete um código do Circuito diário, explora o equipamento e partilha os resultados. Compara rondas sem classificação online.','Interface do jogo em inglês.'],
'pt-BR':[['Crie seu','poder de fogo.'],['Desvie. Adapte.','Sobreviva.'],['Um código.','Sua melhor partida.'],
'Funda armas, descubra projetos e equipe seus robôs. Transforme experimentos na oficina em novas opções de combate.',
'Antecipe ataques dos chefes, desvie e escolha melhorias. Guie seus robôs por ondas sem fim e desafios com três chefes.',
'Repita um código do Circuito diário, explore o equipamento e compartilhe os resultados. Compare partidas sem ranking online.','Interface do jogo em inglês.'],
'ja':[['武器を合成。','自分の戦い方へ。'],['かわして、強化。','生き残れ。'],['同じコードで、','次のベストへ。'],
'武器を合成し、設計図を発見。ロボット部隊に装備して戦いへ。ワークショップでの実験を次の戦術につなげよう。',
'ボスの予告を読み、攻撃をかわし、強化を選ぼう。終わりのないウェーブや3体のボスにロボット部隊で挑戦。',
'デイリーサーキットのコードを再プレイ。装備を試し、リザルトカードを共有しよう。オンラインランキングなしで友達と記録を比較。','ゲーム内表示は英語です。'],
'ko':[['무기를 합성하고','전략을 완성하세요.'],['피하고 강화하며','살아남으세요.'],['같은 코드로','최고 기록에 도전.'],
'무기를 합성하고 설계도를 발견해 로봇 분대에 장착하세요. 작업실의 실험을 새로운 전투 전략으로 이어 가세요.',
'보스의 공격 예고를 읽고 피하며 강화를 선택하세요. 끝없는 웨이브와 보스 3종 도전에 로봇 분대를 이끄세요.',
'일일 서킷 코드를 다시 플레이하고 장비를 시험해 결과 카드를 공유하세요. 온라인 순위표 없이 친구와 기록을 비교하세요.','게임 인터페이스는 영어입니다.'],
'zh-Hans':[['合成武器，','打造你的火力。'],['闪避、强化，','迎战生存挑战。'],['同一个代码，','挑战更好成绩。'],
'合成武器，发现蓝图，为机器人小队装备新发明。把工坊里的实验变成下一场战斗的策略。',
'观察首领的攻击预警，闪避并选择强化。带领机器人小队挑战无尽波次和三首领战斗。',
'重玩每日巡回的挑战代码，探索配装并分享成绩卡。无需在线排行榜，也能与朋友比较战绩。','游戏界面为英语。'],
'zh-Hant':[['合成武器，','打造你的火力。'],['閃避、強化，','迎戰生存挑戰。'],['同一個代碼，','挑戰更好成績。'],
'合成武器，發現藍圖，為機器人小隊裝備新發明。把工坊裡的實驗變成下一場戰鬥的策略。',
'觀察首領的攻擊預警，閃避並選擇強化。帶領機器人小隊挑戰無盡波次和三首領戰鬥。',
'重玩每日巡迴的挑戰代碼，探索配裝並分享成績卡。無需線上排行榜，也能與朋友比較戰績。','遊戲介面為英語。']
};
const campaigns=[
{id:'weapon-fusion',name:'Weapon Fusion • Craft Your Firepower',accent:'#FFC65B',captures:['Store-05-workshop','Store-07-fusion','Store-04-blueprints'],keywordIndices:[0,6,9]},
{id:'boss-survival',name:'Boss Survival • Dodge Adapt Survive',accent:'#6DEAD1',captures:['Store-11-boss','Store-13-overdrive','Store-03-squad'],keywordIndices:[1,3,4,5,7,10]},
{id:'daily-circuit',name:'Daily Circuit • One Code Your Best Run',accent:'#B0A1FF',captures:['Store-12-daily','Store-14-mastery','Store-15-share'],keywordIndices:[2]}
];
const font='Arial,Microsoft YaHei,Meiryo,Malgun Gothic,sans-serif';
const text=(x,y,s,size,color='#F5F6EC',weight=700)=>`<text x="${x}" y="${y}" font-family="${font}" font-size="${size}" font-weight="${weight}" fill="${color}">${esc(s)}</text>`;
const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${w}" height="${h}">${body}</svg>`;
function backdrop(w,h,a){return `<defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#06141D"/><stop offset="1" stop-color="#18383F"/></linearGradient><radialGradient id="glow"><stop stop-color="${a}" stop-opacity=".2"/><stop offset="1" stop-color="${a}" stop-opacity="0"/></radialGradient></defs><rect width="${w}" height="${h}" fill="url(#bg)"/><circle cx="${w*.7}" cy="${h*.5}" r="${w*.7}" fill="url(#glow)"/><g fill="none" stroke="${a}" stroke-opacity=".13" stroke-width="3"><circle cx="${w*.7}" cy="${h*.6}" r="${w*.42}"/><circle cx="${w*.7}" cy="${h*.6}" r="${w*.49}"/><path d="M0 ${h*.85}H${w*.1}L${w*.18} ${h*.77}M${w} ${h*.15}H${w*.9}L${w*.82} ${h*.23}"/></g>`;}
async function exportPng(file,w,h,body){fs.mkdirSync(path.dirname(file),{recursive:true});await sharp(Buffer.from(svg(w,h,body))).flatten({background:'#06141D'}).removeAlpha().png().toFile(file);const b=fs.readFileSync(file),m=await sharp(b).metadata();if(m.width!==w||m.height!==h||m.hasAlpha)throw Error('Invalid export '+file);return {file:path.relative(out,file).replaceAll('\\','/'),width:w,height:h,sha256:hash(b)};}
async function main(){
 fs.mkdirSync(out,{recursive:true}); const manifest={createdOn:'2026-10-08',status:'prepared-not-published',appUILanguage:'English',translationReview:'editorial-not-native-speaker-reviewed',keywordDemandValidated:false,campaigns:[],headers:[]};
 const atlas=fs.readFileSync(path.join(root,'App/Resources/RobotAtlas.png')),am=await sharp(atlas).metadata();
 const bolt=await sharp(atlas).extract({left:0,top:0,width:Math.floor(am.width/4),height:Math.floor(am.height/2)}).png().toBuffer();
 const boltData='data:image/png;base64,'+bolt.toString('base64');
 // Text-free App Store header: one central character, safe for all storefront languages.
 const w=5244,h=2950;
 manifest.headers.push(await exportPng(path.join(out,'Headers/app-store-universal.png'),w,h,backdrop(w,h,'#FFC65B')+`<ellipse cx="2622" cy="2300" rx="780" ry="160" fill="#020A10" opacity=".6"/><image x="1622" y="500" width="2000" height="2000" xlink:href="${boltData}"/>`));
 for(const [locale,c] of Object.entries(copy)){
  const base=JSON.parse(fs.readFileSync(path.join(root,'Docs/Store',locale+'-draft.json'),'utf8')).metadata;
  const themes=JSON.parse(fs.readFileSync(path.join(root,'Docs/Store/CustomProductPages/keyword-themes.json'),'utf8'));
  for(let ci=0;ci<3;ci++){
   const campaign=campaigns[ci],headline=c[ci],promo=c[3+ci];if([...promo].length>170)throw Error(locale+' promo >170');
   const entry={id:campaign.id,referenceName:campaign.name,locale,headline,promotionalText:promo,languageNotice:c[6],
    keywordCandidates:themes[locale][ci].split(','),keywordAssignment:'Only assign terms present in the latest approved version; candidates are unvalidated and may be unavailable before release.',screenshots:[]};
   for(const device of ['iPhone','iPad']){
    const sw=device==='iPhone'?1320:2064,sh=device==='iPhone'?2868:2752;
    for(let i=0;i<3;i++){
     const source=path.join(root,'Docs/Store',device==='iPhone'?'Captures':'iPad-Captures',campaign.captures[i]+'.png'),b=fs.readFileSync(source),m=await sharp(b).metadata();
     const ih=sh-690,iw=Math.floor(ih*m.width/m.height),ix=Math.floor((sw-iw)/2),iy=610;
     const size=Math.min(device==='iPhone'?108:142,Math.floor((sw-170)/(Math.max(...headline.map(t=>[...t].reduce((n,ch)=>n+(/[^\u0000-\u024f]/.test(ch)?1:.59),0)))*1.02)));
     const body=backdrop(sw,sh,campaign.accent)+text(85,115,'SCRAP SQUAD',30,campaign.accent)+text(sw-160,115,String(i+1).padStart(2,'0'),30,campaign.accent)+headline.map((t,j)=>text(80,280+j*(size+28),t,size,j===1?campaign.accent:'#F5F6EC',900)).join('')+text(85,sh-30,c[6],device==='iPhone'?25:30,'#C1D1D5',400)+`<rect x="${ix-12}" y="${iy-12}" width="${iw+24}" height="${ih+24}" rx="26" fill="#020A0E" stroke="${campaign.accent}" stroke-width="3"/><image x="${ix}" y="${iy}" width="${iw}" height="${ih}" xlink:href="data:image/png;base64,${b.toString('base64')}"/>`;
     entry.screenshots.push({...await exportPng(path.join(out,campaign.id,locale,device,`${i+1}.png`),sw,sh,body),device,source:path.relative(root,source).replaceAll('\\','/'),sourceSHA256:hash(b),captureProvenance:'Docs/Store/'+(device==='iPhone'?'Captures':'iPad-Captures')+'/capture-provenance.json; combat-campaign-provenance.json for added scenes',captureIsLatestBuild:false});
    }
   }
   const bannerBody=backdrop(2400,1000,campaign.accent)+text(150,200,'SCRAP SQUAD',55,campaign.accent)+headline.map((t,j)=>text(150,390+j*145,t,Math.min(120,Math.floor(1350/(Math.max(...headline.map(s=>s.length))*.65))),j?campaign.accent:'#F5F6EC',900)).join('')+`<image x="1580" y="100" width="800" height="800" xlink:href="${boltData}"/>`+text(150,895,c[6],28,'#C1D1D5',400);
   entry.banner=await exportPng(path.join(out,campaign.id,locale,'header.png'),2400,1000,bannerBody);
   manifest.campaigns.push(entry);
  }
 }
 fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 fs.mkdirSync(path.join(root,'Docs/Store/CustomProductPages'),{recursive:true});
 fs.writeFileSync(path.join(root,'Docs/Store/CustomProductPages/campaigns.json'),JSON.stringify(manifest,null,2)+'\n');
 const thumbs=[];for(let ci=0;ci<3;ci++)for(let i=0;i<3;i++)thumbs.push({input:await sharp(path.join(out,campaigns[ci].id,'en-GB/iPhone',`${i+1}.png`)).resize(264,574).toBuffer(),left:(ci*3+i)*264,top:0});
 await sharp({create:{width:2376,height:574,channels:3,background:'#06141D'}}).composite(thumbs).png().toFile(path.join(out,'campaign-overview.png'));
 console.log(`Validated ${manifest.campaigns.length} localized campaign packs, 198 screenshots, 33 banners and one App Store header.`);
}
main().catch(e=>{console.error(e);process.exitCode=1});
