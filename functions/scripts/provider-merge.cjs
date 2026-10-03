// One-off, reviewable provider consolidation. Credentials stay inside Firebase CLI.
const fs = require('node:fs');
const path = require('node:path');
const project = 'carepass-b0220';
const database = `projects/${project}/databases/(default)`;
const base = `https://firestore.googleapis.com/v1/${database}`;
const out = path.resolve(__dirname, '../../.local/provider-merge');
const normalize = value => String(value ?? '').trim().toLowerCase().replace(/\s+/g, ' ');
function decode(v) {
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(decode);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k,v])=>[k,decode(v)]));
  if ('integerValue' in v) return Number(v.integerValue);
  return Object.values(v)[0];
}
const data = doc => Object.fromEntries(Object.entries(doc.fields || {}).map(([k,v])=>[k,decode(v)]));
const id = doc => doc.name.split('/').at(-1);
const definitions = [
  {prefix:'care and social', name:'Care and Social Polyclinic', canonical:'b6b2b533-db06-4969-8739-06a79221ae65'},
  {prefix:'lakeside', name:'Lakeside Hospital', canonical:'baffac51-a453-48b2-aff3-0135718a8d8f'},
  {prefix:'entrance university college of health sciences', name:'Entrance University College Of Health Sciences', canonical:'34191316-530a-4256-8285-e83992cfb98c'},
  {prefix:'delta', name:'Delta Diagnostic Center', canonical:'1d8fbba1-5833-434d-b4fb-1063ceaee0b1'},
];
function encode(v) {
  if(v===null) return {nullValue:null};
  if(Array.isArray(v)) return {arrayValue:{values:v.map(encode)}};
  if(typeof v==='object') return {mapValue:{fields:Object.fromEntries(Object.entries(v).map(([k,v])=>[k,encode(v)]))}};
  if(typeof v==='boolean') return {booleanValue:v};
  if(typeof v==='number') return Number.isInteger(v) ? {integerValue:String(v)} : {doubleValue:v};
  return {stringValue:String(v)};
}
const fields = v => Object.fromEntries(Object.entries(v).map(([k,v])=>[k,encode(v)]));
const unique = values => [...new Map(values.filter(Boolean).map(v=>[normalize(v),v])).values()];
function departmentName(p, def) {
  let label=p.name.slice(def.prefix.length).trim();
  if(def.prefix==='delta') label=label.replace(/^Diagnostic Center\s*/i,'');
  return label || 'Hospital Services';
}
async function main() {
  const authPath = process.env.FIREBASE_CLI_AUTH_PATH;
  if (!authPath) throw Error('Set FIREBASE_CLI_AUTH_PATH to installed firebase-tools/lib/auth.js');
  const auth = require(authPath);
  const account = auth.getProjectDefaultAccount(project) || auth.getGlobalDefaultAccount();
  if (!account) throw Error('Firebase CLI login required');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  async function request(url, body) {
    const response = await fetch(url, {method: body ? 'POST' : 'GET', headers: {Authorization: `Bearer ${token.access_token}`, 'Content-Type':'application/json'}, ...(body ? {body:JSON.stringify(body)} : {})});
    const result = await response.json();
    if (!response.ok) throw Error(`${response.status}: ${result.error?.message}`);
    return result;
  }
  async function list(collection) {
    const docs=[]; let pageToken='';
    do {
      const result = await request(`${base}/documents/${collection}?pageSize=300${pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : ''}`);
      docs.push(...(result.documents || [])); pageToken=result.nextPageToken;
    } while(pageToken);
    return docs;
  }
  const db = await request(base);
  if (db.databaseEdition !== 'STANDARD') throw Error('Unexpected database edition');
  fs.mkdirSync(out,{recursive:true});
  if(process.argv.includes('--verify')) {
    const assert=require('node:assert/strict');
    const plan=JSON.parse(fs.readFileSync(path.join(out,'merge-plan.json'),'utf8'));
    const rows=await request(`${base}/documents:batchGet`,{documents:plan.writes.map(w=>w.delete||w.update.name)});
    const found=new Map(rows.filter(r=>r.found).map(r=>[r.found.name,r.found]));
    for(const write of plan.writes) {
      if(write.delete) {assert(!found.has(write.delete),`Duplicate remains: ${write.delete}`);continue;}
      const actual=found.get(write.update.name);
      assert(actual,`Missing document: ${write.update.name}`);
      for(const [key,value] of Object.entries(write.update.fields)) assert.deepEqual(decode(actual.fields[key]),decode(value),`${write.update.name}/${key}`);
    }
    const allProviders=await list('providers');
    const allServices=await list('services');
    const removed=new Set(plan.writes.filter(w=>w.delete?.includes('/providers/')).map(w=>w.delete.split('/').at(-1)));
    assert(!allServices.some(s=>removed.has(data(s).providerId)),'A service still references a removed provider');
    const result={verifiedAt:new Date().toISOString(),verifiedWrites:plan.writes.length,providerCount:allProviders.length,serviceCount:allServices.length,remainingReferencesToMergedProviders:0};
    fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify(result,null,2));
    console.log(JSON.stringify(result,null,2));return;
  }
  if(process.argv.includes('--apply')) {
    const plan=JSON.parse(fs.readFileSync(path.join(out,'merge-plan.json'),'utf8'));
    if(plan.project!==project || plan.database!==database) throw Error('Wrong plan target');
    if(fs.existsSync(path.join(out,'merge-result.json'))) throw Error('Merge already applied; verify instead');
    // Every update/delete carries its audited document version. Firestore applies
    // the entire commit atomically or rejects it if any affected document changed.
    const result=await request(`${base}/documents:commit`,{writes:plan.writes});
    fs.writeFileSync(path.join(out,'merge-result.json'),JSON.stringify(result,null,2));
    const rollback=plan.writes.map((write,i)=> {
      const name=write.delete||write.update.name, original=plan.before[name];
      if(original===null) return {delete:name,currentDocument:{updateTime:result.writeResults[i].updateTime}};
      return {update:{name,fields:original.fields},currentDocument:write.delete ? {exists:false} : {updateTime:result.writeResults[i].updateTime}};
    });
    fs.writeFileSync(path.join(out,'rollback-plan.json'),JSON.stringify({project,database,writes:rollback},null,2));
    console.log(JSON.stringify({committed:result.writeResults.length,commitTime:result.commitTime,summary:plan.summary},null,2));
    return;
  }
  const providers = await list('providers');
  const services = await list('services');
  const banners = await list('home_banners');
  if(process.argv.includes('--prepare')) {
    const before=new Map(); const writes=[]; const mapping=new Map(); const summary=[];
    const now=new Date().toISOString();
    const update=(doc,patch)=>{before.set(doc.name,doc);writes.push({update:{name:doc.name,fields:fields(patch)},updateMask:{fieldPaths:Object.keys(patch)},currentDocument:{updateTime:doc.updateTime}});};
    const create=(name,value)=>{before.set(name,null);writes.push({update:{name,fields:fields(value)},currentDocument:{exists:false}});};
    const remove=doc=>{before.set(doc.name,doc);writes.push({delete:doc.name,currentDocument:{updateTime:doc.updateTime}});};
    const allGroupDocs=[];
    for(const def of definitions) {
      const main=providers.find(doc=>id(doc)===def.canonical);
      if(!main) throw Error(`Canonical provider missing: ${def.name}`);
      const primary=data(main);
      const group=providers.filter(doc=> {
        const p=data(doc);
        return normalize(p.name).startsWith(def.prefix+' ') || normalize(p.name)===def.prefix;
      });
      if(group.length<2) throw Error(`No duplicate group for ${def.name}`);
      for(const doc of group) {
        const p=data(doc);
        if(normalize(p.address)!==normalize(primary.address) || normalize(p.area)!==normalize(primary.area)) throw Error(`Different branch in ${def.name}`);
        if(p.latitude!=null && primary.latitude!=null && (Math.abs(p.latitude-primary.latitude)>0.001 || Math.abs(p.longitude-primary.longitude)>0.001)) throw Error(`Different coordinates in ${def.name}`);
        mapping.set(id(doc),def);
      }
      const types=unique(group.flatMap(doc=>{const p=data(doc);return p.types?.length?p.types:[p.type];}));
      const departments=group.map(doc=>({sourceProviderId:id(doc),...data(doc),name:departmentName(data(doc),def)}));
      const offered=unique([...group.map(doc=>departmentName(data(doc),def)),...group.flatMap(doc=>data(doc).services||[])]);
      update(main,{name:def.name,types,services:offered,totalServices:offered.length,departments,discountPercent:Math.max(...group.map(doc=>Number(data(doc).discountPercent)||0)),mergedProviderIds:group.filter(doc=>id(doc)!==def.canonical).map(id),updatedAt:now});
      for(const doc of group) {
        const p=data(doc); const label=departmentName(p,def);
        // A department becomes a service offering with its own discount,
        // hours, contact details and original image retained.
        const category=({hospital:'consultation',clinic:'consultation',diagnostic:'radiology'})[p.type] || p.type;
        create(`${database}/documents/services/merged-provider-${id(doc)}`,{
          name:label,category,providerId:def.canonical,providerName:def.name,
          discountPercent:Number(p.discountPercent)||0,isAvailable:p.isActive===true,
          description:[p.workingHours && `Hours: ${p.workingHours}`,p.phoneNumber && `Phone: ${p.phoneNumber}`].filter(Boolean).join('\n'),
          workingHours:p.workingHours||'',phoneNumber:p.phoneNumber||'',imageUrl:p.imageUrl||null,
          sourceProviderId:id(doc),createdAt:p.createdAt||now,updatedAt:now,
        });
        if(id(doc)!==def.canonical) remove(doc);
      }
      allGroupDocs.push(...group);
      summary.push({name:def.name,canonicalId:def.canonical,recordsBefore:group.length,types,departments:departments.map(p=>({name:p.name,discountPercent:p.discountPercent,workingHours:p.workingHours}))});
    }
    // Refuse to delete providers with unexpected nested data.
    for(const doc of allGroupDocs) {
      const children=await request(`https://firestore.googleapis.com/v1/${doc.name}:listCollectionIds`,{pageSize:100});
      if(children.collectionIds?.length || children.nextPageToken) throw Error(`Provider has subcollections: ${id(doc)}`);
    }
    const root=await request(`${base}/documents:listCollectionIds`,{pageSize:100});
    if(root.nextPageToken) throw Error('More root collections than expected');
    const refs=new Map();
    const targetIds=[...mapping.keys()];
    for(const collection of root.collectionIds||[]) {
      if(collection==='providers') continue;
      for(let i=0;i<targetIds.length;i+=10) {
        const result=await request(`${base}/documents:runQuery`,{structuredQuery:{from:[{collectionId:collection}],where:{fieldFilter:{field:{fieldPath:'providerId'},op:'IN',value:encode(targetIds.slice(i,i+10))}}}});
        for(const row of result) if(row.document) refs.set(row.document.name,row.document);
      }
    }
    // Two older services reference the former Care and Social provider ID.
    // The stored provider name unambiguously matches the same main facility.
    const existingIds=new Set(providers.map(id));
    for(const doc of services) {
      const s=data(doc);
      if(!existingIds.has(s.providerId) && normalize(s.providerName).replace(/\s/g,'')==='careandsocialpolyclinic') {
        mapping.set(s.providerId,definitions[0]); refs.set(doc.name,doc);
      }
    }
    for(const doc of refs.values()) {
      const def=mapping.get(data(doc).providerId);
      if(def) update(doc,{providerId:def.canonical,...('providerName' in data(doc)?{providerName:def.name}:{}),updatedAt:now});
    }
    const favoriteRows=await request(`${base}/documents:runQuery`,{structuredQuery:{from:[{collectionId:'favorites',allDescendants:true}]}});
    const favorites=favoriteRows.filter(r=>r.document).map(r=>r.document);
    const favoriteTargets=new Map(favorites.map(doc=>[doc.name,doc]));
    let movedFavorites=0;
    for(const doc of favorites) {
      const old=id(doc), def=mapping.get(old);
      if(!def || old===def.canonical) continue;
      const destination=doc.name.slice(0,-old.length)+def.canonical;
      if(!favoriteTargets.has(destination)) {
        create(destination,{...data(doc),providerId:def.canonical});
        favoriteTargets.set(destination,{name:destination});
      }
      remove(doc);movedFavorites++;
    }
    if(writes.length>450) throw Error('Too many writes for one reviewed atomic commit');
    const plan={project,database,preparedAt:now,summary,linkedDocuments:refs.size,movedFavorites,writes,before:Object.fromEntries(before)};
    fs.writeFileSync(path.join(out,'merge-plan.json'),JSON.stringify(plan,null,2));
    console.log(JSON.stringify({summary,providerCountBefore:providers.length,providerCountAfter:providers.length-allGroupDocs.length+definitions.length,linkedDocuments:refs.size,movedFavorites,writes:writes.length},null,2));
    return;
  }
  const buckets=new Map();
  for(const doc of providers) {
    const p=data(doc); const name=normalize(p.name); const address=normalize(p.address); const area=normalize(p.area);
    // Require an address: a shared phone or brand name can describe several branches.
    if(!name || !address) continue;
    const key=JSON.stringify([name,area,address]);
    if(!buckets.has(key)) buckets.set(key,[]);
    buckets.get(key).push(doc);
  }
  const groups=[...buckets.values()].filter(g=>g.length>1).map(docs=>({
    name:data(docs[0]).name, ids:docs.map(id),
    records:docs.map(doc=>({id:id(doc),...data(doc), linkedServices:services.filter(s=>data(s).providerId===id(doc)).length})),
  }));
  const snapshot={project,database,capturedAt:new Date().toISOString(),providers,services,banners};
  fs.writeFileSync(path.join(out,'audit-snapshot.json'),JSON.stringify(snapshot,null,2));
  fs.writeFileSync(path.join(out,'duplicate-groups.json'),JSON.stringify(groups,null,2));
  console.log(JSON.stringify({providerCount:providers.length,serviceCount:services.length,bannerCount:banners.length,groups},null,2));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
