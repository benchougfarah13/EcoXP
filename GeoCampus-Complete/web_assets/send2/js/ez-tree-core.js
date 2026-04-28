/**
 * ============================================
 * EZ-TREE-CORE.JS
 * Ported from @dgreenheck/ez-tree for GeoCampus
 * ============================================
 */

const EZTree = (() => {

    class RNG {
        constructor(seed) {
            this.m_w = (123456789 + seed) & 0xffffffff;
            this.m_z = (987654321 - seed) & 0xffffffff;
            this.mask = 0xffffffff;
        }

        random(max = 1, min = 0) {
            this.m_z = (36969 * (this.m_z & 65535) + (this.m_z >> 16)) & this.mask;
            this.m_w = (18000 * (this.m_w & 65535) + (this.m_w >> 16)) & this.mask;
            let result = ((this.m_z << 16) + (this.m_w & 65535)) >>> 0;
            result /= 4294967296;
            return (max - min) * result + min;
        }
    }

    const Billboard = { Single: 0, Double: 1 };
    const TreeType = { Deciduous: 'Deciduous', Evergreen: 'Evergreen' };
    const BarkType = { Oak: 'Oak', Pine: 'Pine' };
    const LeafType = { Oak: 'Oak', Pine: 'Pine' };

    class Branch {
        constructor(origin, orientation, length, radius, level, sectionCount, segmentCount) {
            this.origin = origin;
            this.orientation = orientation;
            this.length = length;
            this.radius = radius;
            this.level = level;
            this.sectionCount = sectionCount;
            this.segmentCount = segmentCount;
        }
    }

    class TreeOptions {
        constructor() {
            this.seed = 1;
            this.type = TreeType.Deciduous;
            this.bark = {
                type: BarkType.Oak,
                tint: 0xffffff,
                flatShading: false,
                textured: false,
                textureScale: { x: 1, y: 1 }
            };
            this.branch = {
                levels: 3,
                angle: [0, 45, 45, 45],
                children: [0, 2, 3, 3],
                force: { direction: { x: 0, y: 1, z: 0 }, strength: 0.1 },
                gnarliness: [0, 0.1, 0.2, 0.3],
                length: [10, 5, 2, 1],
                radius: [1, 0.5, 0.2, 0.1],
                sections: [10, 5, 3, 2],
                segments: [8, 6, 4, 3],
                start: [0, 0.2, 0.2, 0.2],
                taper: [0.7, 0.7, 0.7, 0.7],
                twist: [0, 0, 0, 0]
            };
            this.leaves = {
                type: LeafType.Oak,
                billboard: Billboard.Double,
                angle: 45,
                count: 20,
                start: 0.5,
                size: 2.0,
                sizeVariance: 0.5,
                tint: 0xffffff,
                alphaTest: 0.5
            };
        }

        copy(json) {
            Object.assign(this, json);
        }
    }

    class Tree extends THREE.Group {
        constructor(options = new TreeOptions()) {
            super();
            this.branchesMesh = new THREE.Mesh();
            this.leavesMesh = new THREE.Mesh();
            this.add(this.branchesMesh);
            this.add(this.leavesMesh);
            this.options = options;
            this.branchQueue = [];
        }

        generate() {
            this.branches = { verts: [], normals: [], indices: [], uvs: [] };
            this.leaves = { verts: [], normals: [], indices: [], uvs: [] };
            this.rng = new RNG(this.options.seed);

            this.branchQueue.push(
                new Branch(
                    new THREE.Vector3(),
                    new THREE.Euler(),
                    this.options.branch.length[0],
                    this.options.branch.radius[0],
                    0,
                    this.options.branch.sections[0],
                    this.options.branch.segments[0],
                ),
            );

            while (this.branchQueue.length > 0) {
                const branch = this.branchQueue.shift();
                this.generateBranch(branch);
            }

            this.createBranchesGeometry();
            this.createLeavesGeometry();
        }

        generateBranch(branch) {
            const indexOffset = this.branches.verts.length / 3;
            let sectionOrientation = branch.orientation.clone();
            let sectionOrigin = branch.origin.clone();
            let sectionLength = branch.length / branch.sectionCount / 
                (this.options.type === 'Deciduous' ? Math.max(1, this.options.branch.levels - 1) : 1);

            let sections = [];
            for (let i = 0; i <= branch.sectionCount; i++) {
                let sectionRadius = branch.radius;
                if (i === branch.sectionCount && branch.level === this.options.branch.levels) {
                    sectionRadius = 0.001;
                } else {
                    sectionRadius *= 1 - this.options.branch.taper[branch.level] * (i / branch.sectionCount);
                }

                let first;
                const segmentCount = branch.segmentCount;
                for (let j = 0; j < segmentCount; j++) {
                    let angle = (2.0 * Math.PI * j) / segmentCount;
                    const vertex = new THREE.Vector3(Math.cos(angle), 0, Math.sin(angle))
                        .multiplyScalar(sectionRadius)
                        .applyEuler(sectionOrientation)
                        .add(sectionOrigin);
                    const normal = new THREE.Vector3(Math.cos(angle), 0, Math.sin(angle))
                        .applyEuler(sectionOrientation).normalize();
                    const uv = new THREE.Vector2(j / segmentCount, (i % 2 === 0) ? 0 : 1);

                    this.branches.verts.push(vertex.x, vertex.y, vertex.z);
                    this.branches.normals.push(normal.x, normal.y, normal.z);
                    this.branches.uvs.push(uv.x, uv.y);
                    if (j === 0) first = { vertex, normal, uv };
                }
                this.branches.verts.push(first.vertex.x, first.vertex.y, first.vertex.z);
                this.branches.normals.push(first.normal.x, first.normal.y, first.normal.z);
                this.branches.uvs.push(1, first.uv.y);

                sections.push({ origin: sectionOrigin.clone(), orientation: sectionOrientation.clone(), radius: sectionRadius });
                sectionOrigin.add(new THREE.Vector3(0, sectionLength, 0).applyEuler(sectionOrientation));

                const gnarliness = Math.max(1, 1 / Math.sqrt(Math.max(0.1, sectionRadius))) * this.options.branch.gnarliness[branch.level];
                sectionOrientation.x += this.rng.random(gnarliness, -gnarliness);
                sectionOrientation.z += this.rng.random(gnarliness, -gnarliness);
            }

            this.generateBranchIndices(indexOffset, branch);

            if (branch.level === this.options.branch.levels) {
                this.generateLeaves(sections);
            } else if (branch.level < this.options.branch.levels) {
                this.generateChildBranches(this.options.branch.children[branch.level], branch.level + 1, sections);
            }
        }

        generateChildBranches(count, level, sections) {
            const radialOffset = this.rng.random();
            for (let i = 0; i < count; i++) {
                let startPos = this.rng.random(1.0, this.options.branch.start[level]);
                const sectionIdx = Math.floor(startPos * (sections.length - 1));
                const sectionA = sections[sectionIdx];
                const sectionB = sections[Math.min(sections.length-1, sectionIdx + 1)];
                const alpha = (startPos - sectionIdx / (sections.length - 1)) / (1 / (sections.length - 1));

                const origin = new THREE.Vector3().lerpVectors(sectionA.origin, sectionB.origin, alpha);
                const radius = this.options.branch.radius[level] * ((1 - alpha) * sectionA.radius + alpha * sectionB.radius);
                
                const qA = new THREE.Quaternion().setFromEuler(sectionA.orientation);
                const qB = new THREE.Quaternion().setFromEuler(sectionB.orientation);
                const parentOri = new THREE.Euler().setFromQuaternion(qB.slerp(qA, alpha));

                const radialAngle = 2.0 * Math.PI * (radialOffset + i / count);
                const q1 = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), this.options.branch.angle[level] * Math.PI / 180);
                const q2 = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0, 1, 0), radialAngle);
                const q3 = new THREE.Quaternion().setFromEuler(parentOri);
                const orientation = new THREE.Euler().setFromQuaternion(q3.multiply(q2.multiply(q1)));

                this.branchQueue.push(new Branch(origin, orientation, this.options.branch.length[level], radius, level, this.options.branch.sections[level], this.options.branch.segments[level]));
            }
        }

        generateLeaves(sections) {
            const radialOffset = this.rng.random();
            for (let i = 0; i < this.options.leaves.count; i++) {
                let startPos = this.rng.random(1.0, this.options.leaves.start);
                const sectionIdx = Math.floor(startPos * (sections.length - 1));
                const sectionA = sections[sectionIdx];
                const sectionB = sections[Math.min(sections.length-1, sectionIdx + 1)];
                const alpha = (startPos - sectionIdx / (sections.length - 1)) / (1 / (sections.length - 1));

                const origin = new THREE.Vector3().lerpVectors(sectionA.origin, sectionB.origin, alpha);
                const qA = new THREE.Quaternion().setFromEuler(sectionA.orientation);
                const qB = new THREE.Quaternion().setFromEuler(sectionB.orientation);
                const parentOri = new THREE.Euler().setFromQuaternion(qB.slerp(qA, alpha));

                const radialAngle = 2.0 * Math.PI * (radialOffset + i / this.options.leaves.count);
                const q1 = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), this.options.leaves.angle * Math.PI / 180);
                const q2 = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0, 1, 0), radialAngle);
                const q3 = new THREE.Quaternion().setFromEuler(parentOri);
                const orientation = new THREE.Euler().setFromQuaternion(q3.multiply(q2.multiply(q1)));

                this.generateLeaf(origin, orientation);
            }
        }

        generateLeaf(origin, orientation) {
            let i = this.leaves.verts.length / 3;
            let size = this.options.leaves.size * (1 + this.rng.random(this.options.leaves.sizeVariance, -this.options.leaves.sizeVariance));
            const W = size, L = size;

            const createLeaf = (rot) => {
                const v = [
                    new THREE.Vector3(-W/2, L, 0), new THREE.Vector3(-W/2, 0, 0),
                    new THREE.Vector3(W/2, 0, 0), new THREE.Vector3(W/2, L, 0)
                ].map(vert => vert.applyEuler(new THREE.Euler(0, rot, 0)).applyEuler(orientation).add(origin));

                v.forEach(vert => this.leaves.verts.push(vert.x, vert.y, vert.z));
                const n = new THREE.Vector3(0, 0, 1).applyEuler(orientation);
                for(let k=0; k<4; k++) this.leaves.normals.push(n.x, n.y, n.z);
                this.leaves.uvs.push(0, 1, 0, 0, 1, 0, 1, 1);
                this.leaves.indices.push(i, i + 1, i + 2, i, i + 2, i + 3);
                i += 4;
            };

            createLeaf(0);
            if (this.options.leaves.billboard === Billboard.Double) createLeaf(Math.PI / 2);
        }

        generateBranchIndices(offset, branch) {
            const N = branch.segmentCount + 1;
            for (let i = 0; i < branch.sectionCount; i++) {
                for (let j = 0; j < branch.segmentCount; j++) {
                    let v1 = offset + i * N + j;
                    let v2 = offset + i * N + (j + 1);
                    let v3 = v1 + N;
                    let v4 = v2 + N;
                    this.branches.indices.push(v1, v3, v2, v2, v3, v4);
                }
            }
        }

        createBranchesGeometry() {
            const g = new THREE.BufferGeometry();
            g.setAttribute('position', new THREE.BufferAttribute(new Float32Array(this.branches.verts), 3));
            g.setAttribute('normal', new THREE.BufferAttribute(new Float32Array(this.branches.normals), 3));
            g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(this.branches.uvs), 2));
            g.setIndex(new THREE.BufferAttribute(new Uint32Array(this.branches.indices), 1));
            this.branchesMesh.geometry.dispose();
            this.branchesMesh.geometry = g;
            this.branchesMesh.material = new THREE.MeshPhongMaterial({ flatShading: this.options.bark.flatShading, color: this.options.bark.tint });
        }

        createLeavesGeometry() {
            const g = new THREE.BufferGeometry();
            g.setAttribute('position', new THREE.BufferAttribute(new Float32Array(this.leaves.verts), 3));
            g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(this.leaves.uvs), 2));
            g.setIndex(new THREE.BufferAttribute(new Uint32Array(this.leaves.indices), 1));
            g.computeVertexNormals();
            this.leavesMesh.geometry.dispose();
            this.leavesMesh.geometry = g;
            this.leavesMesh.material = new THREE.MeshPhongMaterial({ color: this.options.leaves.tint, side: THREE.DoubleSide, alphaTest: this.options.leaves.alphaTest });
        }
    }

    return { Tree, TreeOptions, TreeType, Billboard, BarkType, LeafType };
})();
