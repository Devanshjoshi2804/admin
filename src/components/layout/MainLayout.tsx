import React, { ReactNode, useState, useEffect } from "react";
import { NavLink, useLocation } from "react-router-dom";
import { 
  Truck, 
  Package, 
  CreditCard, 
  Users, 
  Warehouse, 
  Car,
  LayoutDashboard,
  PanelLeft,
  Bell,
  Moon,
  Sun,
  LogOut,
  Settings,
  User,
  Menu,
  Search,
  X,
  AlertCircle,
  RefreshCw
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger
} from "@/components/ui/sheet";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import api from "@/lib/api"; // Import API for real-time data

interface MainLayoutProps {
  children: ReactNode;
  title?: string;
}

interface DynamicMenuBadge {
  count: number;
  variant: "default" | "destructive" | "secondary" | "outline";
}

interface DynamicMenuItem {
  icon: any;
  title: string;
  to: string;
  badge: DynamicMenuBadge | null;
}

// Initial static menu items
const initialMenuItems: DynamicMenuItem[] = [
  { 
    icon: LayoutDashboard, 
    title: "Dashboard", 
    to: "/",
    badge: null 
  },
  { 
    icon: Truck, 
    title: "FTL Booking", 
    to: "/booking",
    badge: null 
  },
  { 
    icon: Package, 
    title: "FTL Trips", 
    to: "/trips",
    badge: { count: 0, variant: "default" }
  },
  { 
    icon: CreditCard, 
    title: "Payment Dashboard", 
    to: "/payments",
    badge: { count: 0, variant: "destructive" }
  },
  { 
    icon: Users, 
    title: "Client Management", 
    to: "/clients",
    badge: null 
  },
  { 
    icon: Warehouse, 
    title: "Supplier Management", 
    to: "/suppliers",
    badge: null 
  },
  { 
    icon: Car, 
    title: "Vehicle Management", 
    to: "/vehicles",
    badge: null 
  },
];

const MainLayout = ({ children, title }: MainLayoutProps) => {
  const [dynamicSidebarContent, setDynamicSidebarContent] = useState<ReactNode | null>(null);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [menuItems, setMenuItems] = useState<DynamicMenuItem[]>(initialMenuItems);
  const [notificationCount, setNotificationCount] = useState<number>(0);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [isRealTimeUpdating, setIsRealTimeUpdating] = useState<boolean>(true);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  // Toggle dark mode
  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDarkMode]);

  // Real-time data fetch for notifications and badges
  useEffect(() => {
    // Initial data load
    fetchRealTimeData();

    // Set up the real-time update interval (every 30 seconds)
    const intervalId = setInterval(() => {
      if (isRealTimeUpdating) {
        fetchRealTimeData();
      }
    }, 30000);

    return () => clearInterval(intervalId);
  }, [isRealTimeUpdating]);

  // Function to fetch real-time data
  const fetchRealTimeData = async () => {
    try {
      // Fetch trips data
      const trips = await api.trips.getAll();
      
      // In Transit trips
      const inTransitTrips = trips.filter(trip => trip.status === "In Transit");
      const pendingPods = trips.filter(trip => !trip.podUploaded && trip.status === "Delivered");
      
      // Payment-related metrics
      const pendingAdvancePayments = trips.filter(trip => trip.advancePaymentStatus !== "Paid");
      const pendingBalancePayments = trips.filter(trip => trip.podUploaded && trip.balancePaymentStatus !== "Paid");
      const totalPendingPayments = pendingAdvancePayments.length + pendingBalancePayments.length;
      
      // Generate new notifications for demo (you'd replace this with actual notification logic)
      const newNotifications = [];
      if (inTransitTrips.length > 0) {
        inTransitTrips.slice(0, 2).forEach(trip => {
          newNotifications.push({
            id: `trip-${trip.id}-${Date.now()}`,
            title: "Trip Status Update",
            description: `Trip #${trip.id} is currently in transit`,
            time: "Just now",
            type: "info"
          });
        });
      }
      
      if (pendingPods.length > 0) {
        newNotifications.push({
          id: `pod-${Date.now()}`,
          title: "POD Required",
          description: `${pendingPods.length} trips awaiting POD upload`,
          time: "1 hour ago",
          type: "warning"
        });
      }
      
      if (totalPendingPayments > 0) {
        newNotifications.push({
          id: `payment-${Date.now()}`,
          title: "Payment Action Required",
          description: `${totalPendingPayments} payments need processing`,
          time: "2 hours ago",
          type: "urgent"
        });
      }
      
      // Update menu badges
      const updatedMenuItems = [...menuItems];
      
      // Update Trip badge
      const tripItemIndex = updatedMenuItems.findIndex(item => item.to === "/trips");
      if (tripItemIndex !== -1) {
        updatedMenuItems[tripItemIndex].badge = {
          count: inTransitTrips.length,
          variant: "default"
        };
      }
      
      // Update Payment badge
      const paymentItemIndex = updatedMenuItems.findIndex(item => item.to === "/payments");
      if (paymentItemIndex !== -1) {
        updatedMenuItems[paymentItemIndex].badge = {
          count: totalPendingPayments,
          variant: totalPendingPayments > 3 ? "destructive" : "default"
        };
      }
      
      // Update state with new data
      setMenuItems(updatedMenuItems);
      setNotifications(prev => [...newNotifications, ...prev].slice(0, 10)); // Keep only 10 most recent
      setNotificationCount(newNotifications.length + notificationCount);
      setLastUpdate(new Date());
      
    } catch (error) {
      console.error("Error fetching real-time data:", error);
    }
  };

  // Toggle theme
  const toggleTheme = () => setIsDarkMode(!isDarkMode);
  
  // Toggle real-time updates
  const toggleRealTimeUpdates = () => {
    setIsRealTimeUpdating(!isRealTimeUpdating);
    if (!isRealTimeUpdating) {
      // If turning back on, fetch immediately
      fetchRealTimeData();
    }
  };

  // Manual refresh data function
  const refreshData = () => {
    fetchRealTimeData();
  };

  // Clear all notifications
  const clearNotifications = () => {
    setNotifications([]);
    setNotificationCount(0);
  };

  // Clone children to pass down the setter function for sidebar content
  const childrenWithProps = React.Children.map(children, (child) => {
    if (React.isValidElement(child)) {
      // @ts-ignore - Ignore type error for adding prop dynamically
      return React.cloneElement(child, { setDynamicSidebarContent });
    }
    return child;
  });

  return (
    <div className="flex flex-col min-h-screen bg-gradient-to-br from-background to-muted/30 dark:from-background dark:to-background/95">
      {/* --- Top Header --- */}
      <header className="sticky top-0 z-30 h-14 border-b bg-white dark:bg-background/95 shadow-sm">
        <div className="flex h-full items-center px-4 w-full">
          {/* Logo with trucking icon */}
          <NavLink to="/" className="flex items-center gap-2 font-semibold mr-4">
            <Truck className="h-5 w-5 text-primary" />
            <span className="text-lg bg-gradient-to-r from-primary to-primary/80 bg-clip-text text-transparent font-bold">CargoDham</span>
          </NavLink>

          {/* Mobile menu button */}
          <Sheet open={mobileMenuOpen} onOpenChange={setMobileMenuOpen}>
            <SheetTrigger asChild className="md:hidden ml-auto">
              <Button variant="ghost" size="sm" className="px-2">
                <Menu className="h-5 w-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-64 p-0">
              <SheetHeader className="p-4 border-b">
                <SheetTitle className="flex items-center gap-2">
                  <Truck className="h-5 w-5 text-primary" />
                  <span className="text-lg">CargoDham</span>
                </SheetTitle>
              </SheetHeader>
              <div className="py-4">
                {menuItems.map((item) => (
                  <NavLink
                    key={item.title}
                    to={item.to}
                    onClick={() => setMobileMenuOpen(false)}
                    className={({ isActive }) =>
                      cn(
                        "flex items-center gap-2 px-4 py-2 text-sm font-medium transition-colors",
                        isActive
                          ? "bg-primary/10 text-primary font-medium"
                          : "text-foreground hover:bg-muted"
                      )
                    }
                  >
                    <item.icon className="h-4 w-4 mr-2" />
                    <span>{item.title}</span>
                    {item.badge && item.badge.count > 0 && (
                      <Badge 
                        variant={item.badge.variant} 
                        className="ml-auto h-5 min-w-[1.25rem] text-xs"
                      >
                        {item.badge.count}
                      </Badge>
                    )}
                  </NavLink>
                ))}
              </div>
            </SheetContent>
          </Sheet>

          {/* Main Navigation Links - Desktop */}
          <div className="hidden md:flex items-center h-full space-x-1 overflow-x-auto no-scrollbar flex-1">
            {menuItems.map((item) => (
              <NavLink
                key={item.title}
                to={item.to}
                className={({ isActive }) =>
                  cn(
                    "flex items-center h-full px-3 py-1 text-sm font-medium transition-colors whitespace-nowrap",
                    isActive
                      ? "bg-primary text-white font-medium"
                      : "text-foreground hover:bg-primary/10 hover:text-primary"
                  )
                }
              >
                <item.icon className="h-4 w-4 mr-1.5 flex-shrink-0" />
                <span>{item.title}</span>
                {item.badge && item.badge.count > 0 && (
                  <Badge 
                    variant="secondary" 
                    className="ml-1 px-1 py-0 h-4 min-w-4 text-[10px] font-bold bg-white text-primary"
                  >
                    {item.badge.count}
                  </Badge>
                )}
              </NavLink>
            ))}
            </div>

          {/* Right side elements */}
          <div className="flex items-center ml-auto gap-1.5">
            {/* Search */}
            <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full">
              <Search className="h-4 w-4" />
            </Button>

            {/* User notification count */}
            <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full relative">
              <Bell className="h-4 w-4" />
              {notificationCount > 0 && (
                <span className="absolute -top-1 -right-1 flex items-center justify-center h-4 w-4 rounded-full bg-red-500 text-[10px] text-white">
                  {notificationCount > 9 ? '9+' : notificationCount}
                </span>
              )}
            </Button>

            {/* Dark/Light Mode Toggle */}
            <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full" onClick={toggleTheme}>
              {isDarkMode ? (
                <Sun className="h-4 w-4" />
              ) : (
                <Moon className="h-4 w-4" />
              )}
            </Button>

            {/* User Menu */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full">
                  <Avatar className="h-7 w-7 ring-2 ring-primary/20">
                    <AvatarImage src="https://i.pravatar.cc/100" alt="User" />
                    <AvatarFallback>JD</AvatarFallback>
                  </Avatar>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuLabel>My Account</DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="cursor-pointer">
                  <User className="h-4 w-4 mr-2" /> Profile
                </DropdownMenuItem>
                <DropdownMenuItem className="cursor-pointer">
                  <Settings className="h-4 w-4 mr-2" /> Settings
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="cursor-pointer text-destructive">
                  <LogOut className="h-4 w-4 mr-2" /> Logout
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </header>

      {/* --- Main Content Area --- */}
      <main className="flex-1 p-4">
        {/* Breadcrumb */}
        <div className="mb-2 text-xs text-muted-foreground flex">
          <span>Home</span>
          {location.pathname !== "/" && (
            <>
              <span className="mx-1.5">/</span>
              <span className="font-medium text-foreground">
                {title || menuItems.find(item => item.to === location.pathname)?.title || "Page"}
              </span>
            </>
          )}
        </div>

        {/* Page Title Header */}
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-xl font-bold text-foreground md:text-2xl">{title}</h1>
          
          {/* Page-specific actions could go here */}
          <div className="flex items-center gap-2">
            {location.pathname === "/trips" && (
              <Button size="sm" className="hidden md:flex">Create New Trip</Button>
            )}
            {location.pathname === "/clients" && (
              <Button size="sm" className="hidden md:flex">Add New Client</Button>
            )}
          </div>
        </div>

        {/* Content Grid (Handles optional sidebar) */}
        <div className={cn(
          "grid gap-4",
          dynamicSidebarContent ? "lg:grid-cols-[1fr_300px]" : "lg:grid-cols-1"
        )}>
          {/* Main Page Content Area */}
          <div className="grid auto-rows-max items-start gap-4">
            {/* Actual Page Content */}
            {childrenWithProps}
          </div>

          {/* Dynamic Sidebar (Rendered only if content exists) */}
          {dynamicSidebarContent && (
            <div className="hidden lg:block sticky top-[80px] h-[calc(100vh-96px)] overflow-y-auto">
              <Card className="shadow-sm border border-border">
                <CardHeader className="px-4 pt-4 pb-2 border-b">
                  <CardTitle className="text-base font-semibold">Filters & Info</CardTitle>
                </CardHeader>
                <CardContent className="text-sm p-4">
                  {dynamicSidebarContent}
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t py-3">
        <div className="container flex flex-col items-center justify-between gap-2 md:h-10 md:flex-row px-4">
          <p className="text-center text-xs text-muted-foreground md:text-left">
            &copy; {new Date().getFullYear()} Cargodham. All rights reserved.
          </p>
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-muted-foreground">
              {isRealTimeUpdating ? 'Real-time updates: Active' : 'Updates paused'}
            </span>
            <span className="text-[10px] text-muted-foreground">•</span>
            <span className="text-[10px] text-muted-foreground">
              Version 1.1.0
            </span>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default MainLayout;

