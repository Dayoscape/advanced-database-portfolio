// ShopCave MongoDB seed (synthetic data). Run inside the Mongo container:
//   mongosh --quiet shopcave /tmp/seed.js
// Creates 100k products (variable attributes per type, embedded latest reviews)
// and 100k orders (embedded items, address and payment).

db = db.getSiblingDB('shopcave');
db.products.drop();
db.orders.drop();

// small seeded random generator so the data is repeatable
function mulberry32(a) {
  return function () {
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
const rnd = mulberry32(42);
const pick = (arr) => arr[Math.floor(rnd() * arr.length)];
const int = (lo, hi) => lo + Math.floor(rnd() * (hi - lo + 1));

const states = ['Lagos','Abuja','Rivers','Kano','Oyo','Enugu','Kaduna','Delta','Ogun','Anambra'];
const categories = ['Phones', 'Laptops', 'Shirts', 'Shoes'];

// each category has DIFFERENT attributes: this is the reason for a document model
function attributesFor(category) {
  switch (category) {
    case 'Phones':
      return { brand: pick(['Tecno','Infinix','Samsung','Apple','Xiaomi']), ram_gb: pick([2,4,6,8,12]),
               storage_gb: pick([32,64,128,256]), battery_mah: int(3000, 6000), dual_sim: rnd() < 0.7 };
    case 'Laptops':
      return { brand: pick(['HP','Dell','Lenovo','Apple','Acer']), ram_gb: pick([4,8,16,32]),
               cpu: pick(['i3','i5','i7','Ryzen 5','M2']), screen_inch: pick([13.3,14,15.6]), ssd_gb: pick([128,256,512,1024]) };
    case 'Shirts':
      return { size: pick(['S','M','L','XL']), colour: pick(['black','white','blue','red','green']),
               material: pick(['cotton','linen','polyester']), fit: pick(['slim','regular']) };
    default: // Shoes
      return { size_eu: int(36, 46), colour: pick(['black','white','brown','blue']),
               type: pick(['sneaker','boot','sandal','formal']), waterproof: rnd() < 0.2 };
  }
}

const tagPool = ['new','sale','bestseller','imported','local','limited','gift'];
const comments = ['Great value', 'Works well', 'Arrived late', 'As described', 'Not bad'];

let batch = [];
for (let i = 1; i <= 100000; i++) {
  const category = categories[i % 4];
  const nReviews = int(0, 3);
  const reviews = [];
  let sum = 0;
  for (let r = 0; r < nReviews; r++) {
    const rating = int(1, 5);
    sum += rating;
    reviews.push({ customerId: int(1, 50000), rating, comment: pick(comments),
                   at: new Date(Date.now() - int(1, 700) * 86400000) });
  }
  batch.push({
    _id: i,                                  // same id as products.product_id in PostgreSQL
    sellerId: int(1, 500),
    name: category.slice(0, -1) + ' ' + i,
    category,
    price: int(500, 500000),
    stock: int(0, 500),
    attributes: attributesFor(category),
    tags: [pick(tagPool), pick(tagPool)],
    reviews,                                 // embedded: latest reviews read together with the product
    reviewStats: { count: nReviews, avg: nReviews ? sum / nReviews : null }
  });
  if (batch.length === 10000) { db.products.insertMany(batch); batch = []; }
}

batch = [];
for (let o = 1; o <= 100000; o++) {
  const items = [];
  const nItems = int(1, 4);
  let total = 0;
  for (let k = 0; k < nItems; k++) {
    const productId = 1 + Math.floor(Math.pow(rnd(), 2.5) * 100000);
    const qty = int(1, 3);
    const unitPrice = int(500, 500000);
    total += qty * unitPrice;
    // price and name copied at time of sale (a snapshot, like order_items.unit_price in SQL)
    items.push({ productId, name: 'Product ' + productId, qty, unitPrice });
  }
  const status = pick(['pending','paid','shipped','delivered','delivered','delivered']);
  batch.push({
    _id: o,
    customerId: int(1, 50000),
    status,
    placedAt: new Date(Date.now() - int(0, 730) * 86400000),
    shippingAddress: { street: int(1, 999) + ' Test Street', city: 'City ' + int(0, 49), state: pick(states) },
    items,
    payment: { method: pick(['card','transfer','cod']), amount: total, status: status === 'pending' ? 'initiated' : 'successful' }
  });
  if (batch.length === 10000) { db.orders.insertMany(batch); batch = []; }
}

print('products: ' + db.products.countDocuments());
print('orders:   ' + db.orders.countDocuments());
printjson(db.products.findOne({ category: 'Phones' }));
printjson(db.products.findOne({ category: 'Shirts' }));
