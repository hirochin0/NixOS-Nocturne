const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const logic=vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[2],'utf8').replace(/^\.pragma library\s*/,''),logic);
for(const [x,y,left,top] of [[100,100,true,true],[1400,100,false,true],[100,800,true,false],[1400,800,false,false]]) {
 const w={x,y,width:300,height:200},target=logic.target(w,1920,1080);
 assert.equal(target.x<0,left);assert.equal(target.y<0,top);
 assert.ok(target.x+w.width<0||target.x>1920);
 assert.ok(target.y+w.height<0||target.y>1080);
 const corners=[[0,0],[1920,0],[0,1080],[1920,1080]];
 const distances=corners.map(([cx,cy])=>(x+150-cx)**2+(y+100-cy)**2);
 assert.equal(distances.indexOf(Math.min(...distances)),(top?0:2)+(left?0:1));
}
const handle={address:'abc',wayland:{name:'capture'}};
const windows=logic.windows({monitorX:-1920,monitorY:0,windows:[{address:'0xabc',at:[-1800,50],size:[600,400]}]},[handle]);
assert.equal(windows[0].x,120);assert.equal(windows[0].y,50);assert.equal(windows[0].source,handle.wayland);
assert.equal(logic.canonicalAddress('0X000AbC'),'abc');
console.log('Nearest corners, off-screen endpoints, monitor offsets and capture handles passed.');
