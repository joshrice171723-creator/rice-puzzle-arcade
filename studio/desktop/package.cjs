const fs = require('node:fs');
const path = require('node:path');
(async () => {
  const ui = path.join(__dirname,'ui');
  fs.mkdirSync(ui,{recursive:true});
  for (const name of ['index.html','dashboard.js','style.css','catalog.json']) fs.copyFileSync(path.join(__dirname,'..',name),path.join(ui,name));
  const png = await require('sharp')(path.join(__dirname,'..','icon.svg')).png().toBuffer();
  fs.writeFileSync(path.join(ui,'icon.png'),png);
  const header=Buffer.alloc(22); header.writeUInt16LE(1,2); header.writeUInt16LE(1,4); header.writeUInt16LE(1,10); header.writeUInt16LE(32,12); header.writeUInt32LE(png.length,14); header.writeUInt32LE(22,18);
  const icon=path.join(ui,'icon.ico'); fs.writeFileSync(icon,Buffer.concat([header,png]));
  const { packager } = await import('@electron/packager');
  const [output] = await packager({dir:__dirname, name:'Game Studio', platform:'win32', arch:'x64', icon, out:path.join(__dirname,'../../artifacts/desktop'), overwrite:true, asar:true, prune:true, ignore:[/^\/package\.cjs$/, /^\/package-lock\.json$/]});
  console.log(output);
})();
