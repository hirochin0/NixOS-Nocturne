.pragma library
// Centers in a 790 x 470 canvas. Every parent precedes its children.
const layout = [
    {x:220,y:60,parent:-1}, {x:390,y:60,parent:0},
    {x:300,y:205,parent:0}, {x:560,y:60,parent:1},
    {x:560,y:180,parent:1}, {x:460,y:310,parent:2},
    {x:300,y:370,parent:2}, {x:710,y:60,parent:3},
    {x:710,y:180,parent:4}, {x:650,y:350,parent:5}
];
function position(index) { return layout[index]; }
function parentIndex(apps, index) {
    const value = apps[index] && apps[index].parent;
    return Number.isInteger(value) && value >= -1 && value < index ? value : layout[index].parent;
}
function depth(apps, index) {
    let depth = 1, parent = parentIndex(apps, index);
    while (parent >= 0) { depth++; parent = parentIndex(apps, parent); }
    return depth;
}
