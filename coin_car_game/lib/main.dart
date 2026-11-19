import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() => runApp(const GameApp());

const bg = Color(0xFF0A1428);
const cardBg = Color(0xFF1B2333);
const dealBg = Color(0xFF10262F);
const teal = Color(0xFF14B8A6);
const badgeBg = Color(0xFF4A4660);

class GameApp extends StatelessWidget {
  const GameApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true)
            .copyWith(scaffoldBackgroundColor: bg),
        home: const Home(),
      );
}

class Pack {
  final String id;
  final int coins;
  final String? badge;
  const Pack(this.id, this.coins, [this.badge]);
}

const packs = [
  Pack('coins_50', 50),
  Pack('coins_60', 60, 'Best Deal'),
  Pack('coins_100', 100, 'Top Selling'),
  Pack('coins_110', 110, 'Best Deal'),
  Pack('coins_200', 200),
  Pack('coins_210', 210, 'Best Deal'),
  Pack('coins_300', 300),
  Pack('coins_310', 310, 'Best Deal'),
  Pack('coins_400', 400),
  Pack('coins_410', 410, 'Best Deal'),
];

class Car {
  final String name;
  final int price;
  const Car(this.name, this.price);
}

const cars = [
  Car('Street racer', 200),
  Car('Sport coupe', 500),
  Car('Super car', 1100),
];

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Map<String, ProductDetails> _products = {};
  int coins = 0;
  int tab = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _sub = _iap.purchaseStream.listen(_onPurchases);
    _loadProducts();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!await _iap.isAvailable()) {
      setState(() => loading = false);
      return;
    }
    final res = await _iap.queryProductDetails(packs.map((p) => p.id).toSet());
    setState(() {
      _products = {for (final p in res.productDetails) p.id: p};
      loading = false;
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased) {
        // TODO: server-e verify kore tarpor coin add korbe.
        final amount = packs.firstWhere((x) => x.id == p.productID).coins;
        setState(() => coins += amount);
      } else if (p.status == PurchaseStatus.error) {
        _toast('Purchase failed. Try again.');
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  void _buy(ProductDetails product) {
    _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  void _buyCar(Car car) {
    if (coins >= car.price) {
      setState(() => coins -= car.price);
      _toast('${car.name} bought');
    } else {
      _toast('Need ${car.price - coins} more coins');
      setState(() => tab = 0);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            _topBar(),
            Expanded(child: tab == 0 ? _store() : _carShop()),
          ]),
          Positioned(left: 24, right: 24, bottom: 16, child: _navPill()),
        ]),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cardBg,
            child: const Icon(Icons.menu),
          ),
          const SizedBox(width: 12),
          Text(tab == 0 ? 'Store' : 'Car shop',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(30)),
            child: Row(children: [
              const Icon(Icons.diamond, color: Colors.lightBlueAccent),
              const SizedBox(width: 8),
              Text('$coins',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      );

  Widget _store() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (_products.isEmpty) {
      return const Center(
          child: Text('Store not available. Install from Play Store.'));
    }
    final items = packs.where((p) => _products.containsKey(p.id)).toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 28,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) => _packCard(items[i], _products[items[i].id]!),
      itemCount: items.length,
    );
  }

  Widget _packCard(Pack pk, ProductDetails p) {
    final deal = pk.badge != null;
    final oldPrice = '\$${(pk.coins * 0.01).toStringAsFixed(2)}';
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: deal ? dealBg : cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: deal ? teal : Colors.white12, width: 1.5),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.diamond,
                    color: Colors.lightBlueAccent, size: 26),
                const SizedBox(width: 8),
                Text('${pk.coins}',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800)),
              ]),
              GestureDetector(
                onTap: () => _buy(p),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: teal, width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (deal)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(oldPrice,
                            style: const TextStyle(
                                color: Color(0xFF0F766E),
                                fontSize: 15,
                                decoration: TextDecoration.lineThrough)),
                      ),
                    Text(p.price,
                        style: const TextStyle(
                            color: teal,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      if (deal)
        Positioned(
          top: -18,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: teal),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 4),
                Text(pk.badge!,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _carShop() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          for (final c in cars)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(children: [
                const Icon(Icons.directions_car, size: 40, color: teal),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.diamond,
                              size: 16, color: Colors.lightBlueAccent),
                          const SizedBox(width: 4),
                          Text('${c.price}'),
                        ]),
                      ]),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: teal,
                      side: const BorderSide(color: teal)),
                  onPressed: () => _buyCar(c),
                  child: const Text('Buy'),
                ),
              ]),
            ),
        ],
      );

  Widget _navPill() => Container(
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFF14111A),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _navItem(Icons.shopping_bag, 0),
          _navItem(Icons.directions_car, 1),
        ]),
      );

  Widget _navItem(IconData icon, int i) => GestureDetector(
        onTap: () => setState(() => tab = i),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tab == i ? const Color(0xFF123A38) : Colors.transparent,
          ),
          child: Icon(icon, size: 30, color: tab == i ? teal : Colors.white54),
        ),      );
}
