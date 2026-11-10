.pragma library
// Three main branches from the moon, with children growing from application nodes.
const layout = [
    {x:240,y:60,parent:-1}, {x:220,y:215,parent:-1},
    {x:100,y:365,parent:-1}, {x:460,y:60,parent:0},
    {x:460,y:160,parent:0}, {x:450,y:250,parent:1},
    {x:450,y:380,parent:1}, {x:300,y:410,parent:2},
    {x:260,y:515,parent:2}, {x:680,y:310,parent:5}
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

function openDelay(apps, index) {
    let trunk = index, parent = parentIndex(apps, index);
    while (parent >= 0) { trunk = parent; parent = parentIndex(apps, parent); }
    return (depth(apps, index) - 1) * 240 + (trunk % 3) * 70 + (index % 2) * 25;
}
