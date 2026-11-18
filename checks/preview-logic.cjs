const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const c=vm.createContext({});vm.runInContext(fs.readFileSync(process.argv[2],'utf8'),c);
for(const screen of [[1920,1080],[1280,800],[800,600],[3840,2160],[2560,1440],[480,320]]) {
 for(const source of [[1920,1080],[1080,1920],[3840,2160],[500,300],[0,0],[10000,100]]) {
  const d=c.dimensions(...source,...screen);
  assert(d.width>0&&d.height>0&&d.width<=1000&&d.height<=900);
  assert(d.width<=screen[0]-32&&d.height<=screen[1]-90);
  if(source[0]&&source[1]) assert(Math.abs(d.imageWidth/d.imageHeight-source[0]/source[1])<1e-8);
 }
}
assert.equal(c.windowSize({lastIpcObject:{size:[900,600]}}).width,900);
assert.equal(c.windowSize(null).width,1280);
assert.equal(c.windowSize({lastIpcObject:{size:[-1,0]}}).height,800);
console.log('Thumbnail bounds <=1000x900, screen limits, portrait/landscape aspect ratios and unknown windows passed.');
