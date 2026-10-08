// Duo-sized marketing layouts around full, genuine iPad gameplay captures.
// These exports do not claim capture or testing on a Duo simulator/device.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),out=path.join(root,'Marketing/iPhoneDuo');
const campaign=JSON.parse(fs.readFileSync(path.join(root,'Docs/Store/en-GB-draft.json'),'utf8'));
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
 const manifest={createdOn:'2026-10-08',locale:'en-GB',format:'Opaque RGB PNG',captureDevice:'13-inch iPad simulator',nativeDuoCapture:false,method:'Full original UI scaled proportionally inside a marketing layout; no gameplay cropping, stretching or replacement.',specification:'https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/',sets:[]};
 for(const [display,w,h] of [['inner',2007,2853],['outer',1398,2034]]){
  const s=w/2007,folder=path.join(out,display);fs.mkdirSync(folder,{recursive:true});
  const entry={display,width:w,height:h,screenshots:[]};
  for(const shot of campaign.screenshots){
   const source=path.join(root,'Docs/Store/iPad-Captures',shot.capture+'.png'),bytes=fs.readFileSync(source),m=await sharp(bytes).metadata();
   const accent=shot.order%2?'#FFCE65':'#79E6C6',y=Math.round(550*s),ih=Math.floor(h-y-85*s),iw=Math.round(ih*m.width/m.height),x=Math.round((w-iw)/2);
   const size=Math.min(122*s,(w-240*s)/(Math.max(...shot.headline.map(t=>t.length))*.65));
   const text=(x,y,t,size,color='#F5F7F0',weight=700)=>`<text x="${x}" y="${y}" font-family="Arial,sans-serif" font-size="${size}" font-weight="${weight}" fill="${color}">${esc(t)}</text>`;
   const svg=`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${w}" height="${h}"><defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#153A43"/><stop offset="1" stop-color="#09151B"/></linearGradient></defs><rect width="${w}" height="${h}" fill="url(#bg)"/><g fill="none" stroke="${accent}" stroke-opacity=".11" stroke-width="${3*s}"><circle cx="${w*.6}" cy="${h*.6}" r="${w*.6}"/><circle cx="${w*.6}" cy="${h*.6}" r="${w*.7}"/></g>${text(120*s,120*s,'SCRAP SQUAD',34*s,accent)}${text(w-220*s,120*s,String(shot.order).padStart(2,'0')+' / 10',30*s,accent)}${shot.headline.map((t,i)=>text(120*s,(260+i*135)*s,t,size,i?accent:'#F5F7F0',900)).join('')}${text(123*s,466*s,shot.supportingCopy,37*s,'#C1D3D5',400)}${text(123*s,515*s,shot.keyword,25*s,accent)}<rect x="${x-12*s}" y="${y-12*s}" width="${iw+24*s}" height="${ih+24*s}" rx="${18*s}" fill="#03090C" stroke="${accent}" stroke-width="${3*s}"/><image x="${x}" y="${y}" width="${iw}" height="${ih}" xlink:href="data:image/png;base64,${bytes.toString('base64')}"/>${text(120*s,h-25*s,'BUILD. MERGE. SURVIVE.',24*s,'#A2BABB')}</svg>`;
   const file=String(shot.order).padStart(2,'0')+'-'+shot.capture.replace(/^Store-\d+-/,'')+'.png',target=path.join(folder,file);
   await sharp(Buffer.from(svg)).flatten({background:'#09151B'}).removeAlpha().png().toFile(target);
   const final=fs.readFileSync(target),meta=await sharp(final).metadata();
   if(meta.width!==w||meta.height!==h||meta.hasAlpha)throw Error('Invalid Duo export');
   entry.screenshots.push({order:shot.order,file:display+'/'+file,source:path.relative(root,source).replaceAll('\\','/'),sourceSHA256:hash(bytes),exportSHA256:hash(final),width:w,height:h});
  }
  const th=Math.round(300*h/w),tiles=[];
  for(let i=0;i<10;i++)tiles.push({input:await sharp(path.join(out,entry.screenshots[i].file)).resize(300,th).toBuffer(),left:(i%5)*300,top:Math.floor(i/5)*th});
  await sharp({create:{width:1500,height:th*2,channels:3,background:'#09151B'}}).composite(tiles).png().toFile(path.join(folder,'contact-sheet.png'));
  manifest.sets.push(entry);
 }
 fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 console.log('Validated 20 Duo-sized screenshots: ten inner, ten outer; opaque RGB, original UI aspect ratio preserved.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
