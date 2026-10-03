/* Deterministic vector layout around unaltered, full-frame simulator captures.
 * Requires sharp (npm install --no-save sharp) or the bundled runtime NODE_PATH.
 * Usage: node Tools/render_store_screenshots.cjs <capture directory>
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const input = path.resolve(process.argv[2] || path.join(root, 'Docs/Store/Captures'));
const output = path.join(root, 'Docs/Store/Screenshots/en-GB');
fs.mkdirSync(output, { recursive: true });
const campaign = JSON.parse(fs.readFileSync(path.join(root, 'Docs/Store/en-GB-draft.json'), 'utf8'));
const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const colors = ['#FFCE65','#79E6C6','#FFCE65','#79E6C6','#A9ADFF','#FFCE65','#79E6C6','#A9ADFF','#FFCE65','#79E6C6'];
async function main() {
  const manifest = {locale:'en-GB',width:1320,height:2868,format:'PNG RGB without alpha',status:'draft-for-review',screenshots:[]};
  for (const shot of campaign.screenshots) {
    const source = path.join(input, shot.capture + '.png');
    const bytes = fs.readFileSync(source);
    const dimensions = await sharp(bytes).metadata();
    const width = 914, height = Math.round(width * dimensions.height / dimensions.width);
    if(height > 2040) throw new Error('Capture aspect ratio exceeds layout safe area');
    const x = 203, y = 727, accent = colors[shot.order-1];
    const longest = Math.max(...shot.headline.map(s=>s.length));
    const size = Math.min(126, Math.floor(1120/(longest*0.66)));
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1320" height="2868" viewBox="0 0 1320 2868">
      <defs>
        <linearGradient id="bg" x2="1" y2="1"><stop stop-color="#102A32"/><stop offset=".65" stop-color="#09151B"/><stop offset="1" stop-color="#173C42"/></linearGradient>
        <radialGradient id="glow"><stop stop-color="${accent}" stop-opacity=".22"/><stop offset="1" stop-color="${accent}" stop-opacity="0"/></radialGradient>
        <linearGradient id="rim" x2="1" y2="1"><stop stop-color="${accent}"/><stop offset=".4" stop-color="#31454B"/><stop offset="1" stop-color="#759097"/></linearGradient>
        <clipPath id="screen"><rect x="${x}" y="${y}" width="${width}" height="${height}" rx="64"/></clipPath>
      </defs>
      <rect width="1320" height="2868" fill="url(#bg)"/>
      <circle cx="990" cy="1440" r="1030" fill="url(#glow)"/>
      <g fill="none" stroke="${accent}" stroke-opacity=".11" stroke-width="3">
        <path d="M0 740H88L148 800V2120L80 2188H0M1320 950H1235L1180 1005V2420L1260 2500H1320"/>
        <circle cx="660" cy="1850" r="620"/><circle cx="660" cy="1850" r="735"/>
        <path d="M0 2775H144M1176 2775H1320"/>
      </g>
      <rect x="86" y="104" width="9" height="34" rx="4" fill="${accent}"/>
      <text x="116" y="132" fill="#D1DFE0" font-family="Arial,sans-serif" font-size="30" font-weight="700" letter-spacing="5">SCRAP SQUAD</text>
      <text x="1234" y="132" text-anchor="end" fill="${accent}" font-family="Arial,sans-serif" font-size="30" font-weight="700">${String(shot.order).padStart(2,'0')} / 10</text>
      ${shot.headline.map((line,i)=>`<text x="86" y="${300+i*145}" fill="${i===1?accent:'#F5F7F0'}" font-family="Arial Black,Arial,sans-serif" font-size="${size}" font-weight="900" letter-spacing="-4">${escape(line)}</text>`).join('')}
      <text x="90" y="546" fill="#C1D3D5" font-family="Arial,sans-serif" font-size="39">${escape(shot.supportingCopy)}</text>
      <rect x="88" y="592" width="72" height="5" rx="2" fill="${accent}"/>
      <text x="181" y="606" fill="${accent}" font-family="Arial,sans-serif" font-size="25" font-weight="700" letter-spacing="4">${escape(shot.keyword)}</text>
      <rect x="${x-25}" y="${y-25}" width="${width+50}" height="${height+50}" rx="90" fill="#03090C" stroke="url(#rim)" stroke-width="6"/>
      <image x="${x}" y="${y}" width="${width}" height="${height}" clip-path="url(#screen)" xlink:href="data:image/png;base64,${bytes.toString('base64')}"/>
      <text x="660" y="2800" text-anchor="middle" fill="#A2BABB" font-family="Arial,sans-serif" font-size="25" font-weight="700" letter-spacing="5">BUILD IT. MERGE IT. SURVIVE.</text>
    </svg>`;
    const filename = String(shot.order).padStart(2,'0')+'-'+shot.capture.replace(/^Store-\d+-/,'')+'.png';
    fs.writeFileSync(path.join(output,filename.replace('.png','.svg')),svg);
    await sharp(Buffer.from(svg)).flatten({background:'#09151B'}).removeAlpha().png().toFile(path.join(output,filename));
    const final = fs.readFileSync(path.join(output,filename));
    const result = await sharp(final).metadata();
    if(result.width!==1320||result.height!==2868||result.hasAlpha) throw new Error('Export specification failed');
    manifest.screenshots.push({...shot,file:filename,source:path.relative(root,source).replaceAll('\\','/'),sourceSHA256:hash(bytes),exportSHA256:hash(final)});
  }
  const thumbs = await Promise.all(manifest.screenshots.map(async (shot,i)=>({input:await sharp(path.join(output,shot.file)).resize(264,574).toBuffer(),left:(i%5)*264,top:Math.floor(i/5)*574})));
  await sharp({create:{width:1320,height:1148,channels:3,background:'#09151B'}}).composite(thumbs).png().toFile(path.join(output,'contact-sheet.png'));
  fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log('Exported 10 RGB screenshots (1320 × 2868), editable SVG sources, contact sheet and provenance manifest.');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
