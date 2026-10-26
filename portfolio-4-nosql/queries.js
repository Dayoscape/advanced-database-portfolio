// Example queries on the ShopCave document model.  Run: mongosh --quiet shopcave /tmp/queries.js
db = db.getSiblingDB('shopcave');

print('\n--- Q1: phones with 8+ GB RAM under N300,000, cheapest first (attributes only phones have)');
printjson(db.products.find(
  { category: 'Phones', 'attributes.ram_gb': { $gte: 8 }, price: { $lt: 300000 } },
  { name: 1, price: 1, 'attributes.ram_gb': 1, 'attributes.brand': 1 }
).sort({ price: 1 }).limit(3).toArray());

print('\n--- Q2: black size-M shirts (attributes only shirts have)');
print('count = ' + db.products.countDocuments({ category: 'Shirts', 'attributes.size': 'M', 'attributes.colour': 'black' }));

print('\n--- Q3: products tagged "bestseller" (array field)');
print('count = ' + db.products.countDocuments({ tags: 'bestseller' }));

print('\n--- Q4: aggregation: product count and average price per category');
printjson(db.products.aggregate([
  { $group: { _id: '$category', products: { $sum: 1 }, avgPrice: { $avg: '$price' } } },
  { $sort: { _id: 1 } }
]).toArray());

print('\n--- Q5: aggregation: best rated Phones with 2+ reviews (uses the embedded reviewStats)');
printjson(db.products.aggregate([
  { $match: { category: 'Phones', 'reviewStats.count': { $gte: 2 } } },
  { $sort: { 'reviewStats.avg': -1, 'reviewStats.count': -1 } },
  { $limit: 3 },
  { $project: { name: 1, 'reviewStats': 1 } }
]).toArray());

print('\n--- Q6: one customer\'s order history in ONE read (items are embedded, no join needed)');
printjson(db.orders.find({ customerId: 123 }, { items: 1, status: 1, 'payment.amount': 1 }).limit(2).toArray());

print('\n--- Q7: aggregation: top 5 products by revenue (unwind the embedded items)');
printjson(db.orders.aggregate([
  { $match: { status: { $ne: 'pending' } } },
  { $unwind: '$items' },
  { $group: { _id: '$items.productId', revenue: { $sum: { $multiply: ['$items.qty', '$items.unitPrice'] } } } },
  { $sort: { revenue: -1 } },
  { $limit: 5 }
]).toArray());
