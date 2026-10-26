// Before/after indexes with explain("executionStats"). Run: mongosh --quiet shopcave /tmp/explain_indexes.js
db = db.getSiblingDB('shopcave');
db.products.dropIndexes();     // keeps only the default _id index
db.orders.dropIndexes();

function plan(w) {
  const s = JSON.stringify(w);
  return s.includes('IXSCAN') ? 'IXSCAN (index)' : (s.includes('COLLSCAN') ? 'COLLSCAN (full scan)' : '?');
}
function run(label, coll, query, sort) {
  let c = db[coll].find(query);
  if (sort) c = c.sort(sort);
  const e = c.explain('executionStats');
  const es = e.executionStats;
  print(label.padEnd(34) + plan(e.queryPlanner.winningPlan).padEnd(22) +
        ('examined=' + es.totalDocsExamined).padEnd(18) + ('returned=' + es.nReturned).padEnd(15) + ('ms=' + es.executionTimeMillis));
}

const q1 = { category: 'Phones', 'attributes.ram_gb': { $gte: 8 }, price: { $lt: 300000 } };
const q2 = { category: 'Shirts', 'attributes.size': 'M', 'attributes.colour': 'black' };
const q3 = { tags: 'bestseller' };
const q6 = { customerId: 123 };

print('=== BEFORE indexes');
run('Q1 phones ram>=8, price<300k', 'products', q1, { price: 1 });
run('Q2 black M shirts', 'products', q2);
run('Q3 tag bestseller', 'products', q3);
run('Q6 customer 123 orders', 'orders', q6);

db.products.createIndex({ category: 1, 'attributes.ram_gb': 1, price: 1 });
db.products.createIndex({ category: 1, 'attributes.size': 1, 'attributes.colour': 1 });
db.products.createIndex({ tags: 1 });                      // multikey index (array field)
db.orders.createIndex({ customerId: 1, placedAt: -1 });

print('\n=== AFTER indexes');
run('Q1 phones ram>=8, price<300k', 'products', q1, { price: 1 });
run('Q2 black M shirts', 'products', q2);
run('Q3 tag bestseller', 'products', q3);
run('Q6 customer 123 orders', 'orders', q6);

print('\nIndexes on products:');
db.products.getIndexes().forEach(i => print('  ' + i.name));
