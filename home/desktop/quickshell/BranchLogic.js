.pragma library
// Three main branches from the moon, with children growing from application nodes.
const layout = [
    {x:250,y:95,parent:-1}, {x:225,y:250,parent:-1},
    {x:115,y:400,parent:-1}, {x:495,y:60,parent:0},
    {x:470,y:215,parent:0}, {x:490,y:335,parent:1},
    {x:390,y:440,parent:1}, {x:300,y:460,parent:2},
    {x:195,y:535,parent:2}, {x:700,y:290,parent:5}
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
