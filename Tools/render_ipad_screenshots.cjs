// Frame actual 13-inch iPad captures without cropping or replacing their UI.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const input = path.resolve(process.argv[2]);
const output = path.join(root, 'Docs/Store/Screenshots/iPad-en-GB');
const campaign = JSON.parse(fs.readFileSync(path.join(root, 'Docs/Store/en-GB-draft.json'), 'utf8'));
const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
async function main() {
  fs.mkdirSync(output, {recursive:true});
  const manifest = {locale:'en-GB',device:'13-inch iPad',width:2064,height:2752,screenshots:[]};
  for (const shot of campaign.screenshots) {
    const source = path.join(input, shot.capture + '.png');
    const bytes = fs.readFileSync(source);
    const meta = await sharp(bytes).metadata();
    if (meta.width !== 2064 || meta.height !== 2752) throw Error('Expected actual 13-inch iPad portrait capture');
    const width = 1530, height = 2040, x = 267, y = 620;
    const accent = shot.order % 2 ? '#FFCE65' : '#79E6C6';
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="2064" height="2752">
      <defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#153A43"/><stop offset="1" stop-color="#09151B"/></linearGradient></defs>
      <rect width="2064" height="2752" fill="url(#bg)"/>
      <text x="136" y="135" fill="${accent}" font-family="Arial,sans-serif" font-size="38" font-weight="700" letter-spacing="7">SCRAP SQUAD</text>
      <text x="1928" y="135" text-anchor="end" fill="${accent}" font-family="Arial,sans-serif" font-size="38">${String(shot.order).padStart(2,'0')} / 10</text>
      ${shot.headline.map((line,i)=>`<text x="136" y="${300+i*133}" fill="${i===1?accent:'#F5F7F0'}" font-family="Arial Black,Arial,sans-serif" font-size="120" font-weight="900">${escape(line)}</text>`).join('')}
      <text x="140" y="510" fill="#C1D3D5" font-family="Arial,sans-serif" font-size="43">${escape(shot.supportingCopy)}</text>
      <text x="140" y="574" fill="${accent}" font-family="Arial,sans-serif" font-size="28" font-weight="700" letter-spacing="5">${escape(shot.keyword)}</text>
      <rect x="${x-17}" y="${y-17}" width="${width+34}" height="${height+34}" rx="22" fill="#03090C" stroke="${accent}" stroke-width="4"/>
      <image x="${x}" y="${y}" width="${width}" height="${height}" xlink:href="data:image/png;base64,${bytes.toString('base64')}"/>
      <text x="1032" y="2720" text-anchor="middle" fill="#A2BABB" font-family="Arial,sans-serif" font-size="25" letter-spacing="5">BUILD IT. MERGE IT. SURVIVE.</text></svg>`;
    const file = String(shot.order).padStart(2,'0')+'-'+shot.capture.replace(/^Store-\d+-/,'')+'.png';
    fs.writeFileSync(path.join(output,file.replace('.png','.svg')),svg);
    await sharp(Buffer.from(svg)).flatten({background:'#09151B'}).removeAlpha().png().toFile(path.join(output,file));
    manifest.screenshots.push({order:shot.order,file,source:path.relative(root,source).replaceAll('\\','/'),sourceSHA256:hash(bytes),exportSHA256:hash(fs.readFileSync(path.join(output,file)))});
  }
  fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log('Exported ten genuine iPad screenshot frames at 2064 × 2752.');
}
main().catch(error => {console.error(error);process.exitCode=1;});
