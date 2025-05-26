// Main menu items
List<MenuItem> get _menuItems => [
  MenuItem(
    title: 'Dashboard',
    icon: Icons.dashboard,
    path: '/',
  ),
  MenuItem(
    title: 'FTL Trips',
    icon: Icons.local_shipping,
    path: '/trips',
  ),
  MenuItem(
    title: 'Create FTL Booking',
    icon: Icons.add_circle_outline,
    path: '/trips/new',
  ),
  MenuItem(
    title: 'Payment Dashboard',
    icon: Icons.payments_outlined,
    path: '/payments',
  ),
  MenuItem(
    title: 'Clients',
    icon: Icons.people_alt_outlined,
    path: '/clients',
  ),
]; 