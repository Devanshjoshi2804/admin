import React, { useState, useEffect } from "react";
import MainLayout from "@/components/layout/MainLayout";
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { trips, clients, suppliers, vehicles } from "@/data/mockData";
import api from "@/lib/api";
import { useToast } from "@/hooks/use-toast";
import { 
  Package,
  Clock,
  AlertCircle,
  Receipt,
  UsersRound, 
  Truck,
  Building,
  FileText,
  ArrowRight,
  BarChart4,
  PieChart,
  ArrowUpRight,
  RefreshCw,
  ChevronRight
} from "lucide-react";
import { Link } from "react-router-dom";

// Helper function to format numbers
function formatCurrency(num: number) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0
  }).format(num);
}

// Helper function to calculate margin percentage
function calculateMarginPercentage(revenue: number, margin: number): string {
  if (revenue === 0) return "0.0%";
  return (margin / revenue * 100).toFixed(1) + "%";
}

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState("overview");
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(true);
  const [dashboardData, setDashboardData] = useState({
    totalTrips: 0,
    inTransitTrips: 0,
    pendingAdvancePayments: 0,
    pendingBalancePayments: 0,
    podPending: 0,
    bookedTrips: 0,
    completedTrips: 0,
    issuesReported: 0,
    totalClients: 0,
    totalSuppliers: 0,
    totalVehicles: 0,
    totalRevenue: 0,
    totalMargin: 0
  });

  // Fetch data for dashboard
  useEffect(() => {
    const fetchDashboardData = async () => {
      setIsLoading(true);
      try {
        // Fetch all required data
        const [allTrips, allClients, allSuppliers, allVehicles] = await Promise.all([
          api.trips.getAll(),
          api.clients.getAll(),
          api.suppliers.getAll(),
          api.vehicles.getAll()
        ]);

        // Process and calculate dashboard metrics
        const bookedTrips = allTrips.filter(trip => trip.status === "Booked").length;
        const inTransitTrips = allTrips.filter(trip => trip.status === "In Transit").length;
        const deliveredTrips = allTrips.filter(trip => trip.status === "Delivered").length;
        const completedTrips = allTrips.filter(trip => trip.status === "Completed").length;
        
        const pendingAdvancePayments = allTrips.filter(trip => trip.advancePaymentStatus !== "Paid").length;
        const pendingBalancePayments = allTrips.filter(trip => trip.podUploaded && trip.balancePaymentStatus !== "Paid").length;
        const podPending = allTrips.filter(trip => !trip.podUploaded && trip.status === "Delivered").length;
        const issuesReported = allTrips.filter(trip => trip.status === "In Transit" && Math.random() > 0.7).length; // Mock data

        const totalRevenue = allTrips.reduce((sum, trip) => sum + trip.clientFreight, 0);
        const totalSupplierCost = allTrips.reduce((sum, trip) => sum + trip.supplierFreight, 0);
        const totalMargin = totalRevenue - totalSupplierCost;

        setDashboardData({
          totalTrips: allTrips.length,
          inTransitTrips,
          pendingAdvancePayments,
          pendingBalancePayments,
          podPending,
          bookedTrips,
          completedTrips,
          issuesReported,
          totalClients: allClients.length,
          totalSuppliers: allSuppliers.length,
          totalVehicles: allVehicles.length,
          totalRevenue,
          totalMargin
        });

        setIsLoading(false);
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
        toast({
          title: "Error",
          description: "Failed to load dashboard data.",
          variant: "destructive",
        });
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, [toast]);

  // Refresh data function
  const refreshData = () => {
    toast({
      title: "Refreshing",
      description: "Updating dashboard data...",
    });
    location.reload();
  };

  // Completion percentage calculation
  const tripCompletionPercentage = dashboardData.totalTrips ? 
    Math.round((dashboardData.completedTrips / dashboardData.totalTrips) * 100) : 0;

  return (
    <MainLayout title="Dashboard">
      {/* Dashboard Tabs */}
      <div className="mb-6">
        <Tabs defaultValue="overview" value={activeTab} onValueChange={setActiveTab}>
          <div className="flex items-center justify-between mb-4">
            <TabsList>
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="trips">Trip Analytics</TabsTrigger>
              <TabsTrigger value="finance">Financial</TabsTrigger>
              <TabsTrigger value="performance">Performance</TabsTrigger>
            </TabsList>
            <Button variant="outline" size="sm" onClick={refreshData} className="gap-1">
              <RefreshCw className="h-3.5 w-3.5" />
              <span>Refresh</span>
            </Button>
          </div>

          <TabsContent value="overview" className="space-y-6">
            {/* Stats Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Total Trips */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">Total Trips</CardTitle>
                  <Package className="h-4 w-4 text-blue-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.totalTrips}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Trips created in system
                  </p>
                </CardContent>
              </Card>

              {/* In Transit */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">In Transit</CardTitle>
                  <Clock className="h-4 w-4 text-amber-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.inTransitTrips}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Trips currently in transit
                  </p>
                </CardContent>
              </Card>

              {/* Pending Payments */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">Pending Payments</CardTitle>
                  <Receipt className="h-4 w-4 text-violet-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.pendingAdvancePayments + dashboardData.pendingBalancePayments}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Payments waiting for processing
                  </p>
                </CardContent>
              </Card>

              {/* POD Pending */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">POD Pending</CardTitle>
                  <FileText className="h-4 w-4 text-orange-500" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.podPending}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Trips waiting for POD upload
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Trip and Payment Status */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Trip Status Summary */}
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-lg">Trip Status Summary</CardTitle>
                  <CardDescription>Overview of current trip statuses</CardDescription>
                </CardHeader>
                <CardContent className="pb-2">
                  <div className="space-y-4">
                    {/* Booked */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-2 h-2 rounded-full bg-blue-500 mr-2"></div>
                        <span className="text-sm">Booked</span>
                      </div>
                      <span className="font-medium">{dashboardData.bookedTrips}</span>
                    </div>
                    <Progress 
                      value={dashboardData.totalTrips ? (dashboardData.bookedTrips / dashboardData.totalTrips) * 100 : 0} 
                      className="h-2" 
                    />

                    {/* In Transit */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-2 h-2 rounded-full bg-amber-500 mr-2"></div>
                        <span className="text-sm">In Transit</span>
                      </div>
                      <span className="font-medium">{dashboardData.inTransitTrips}</span>
                    </div>
                    <Progress 
                      value={dashboardData.totalTrips ? (dashboardData.inTransitTrips / dashboardData.totalTrips) * 100 : 0} 
                      className="h-2 [&>*]:bg-amber-500" 
                    />

                    {/* Completed */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-2 h-2 rounded-full bg-green-500 mr-2"></div>
                        <span className="text-sm">Completed</span>
                      </div>
                      <span className="font-medium">{dashboardData.completedTrips}</span>
                    </div>
                    <Progress 
                      value={dashboardData.totalTrips ? (dashboardData.completedTrips / dashboardData.totalTrips) * 100 : 0} 
                      className="h-2 [&>*]:bg-green-500" 
                    />

                    {/* Issues Reported */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-2 h-2 rounded-full bg-red-500 mr-2"></div>
                        <span className="text-sm">Issues Reported</span>
                      </div>
                      <span className="font-medium">{dashboardData.issuesReported}</span>
                    </div>
                    <Progress 
                      value={dashboardData.totalTrips ? (dashboardData.issuesReported / dashboardData.totalTrips) * 100 : 0} 
                      className="h-2 [&>*]:bg-red-500" 
                    />
                  </div>
                </CardContent>
                <CardFooter className="pt-2 pb-4">
                  <div className="w-full">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium uppercase">Trip Completion</span>
                      <Badge variant={tripCompletionPercentage > 80 ? "default" : "outline"}>
                        {tripCompletionPercentage}%
                      </Badge>
                    </div>
                    <Progress value={tripCompletionPercentage} className="h-1.5" />
                  </div>
                </CardFooter>
              </Card>

              {/* Payment Status */}
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-lg">Payment Status</CardTitle>
                  <CardDescription>Summary of payment statuses</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Advance Payments (Pending) */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-2 h-2 rounded-full bg-blue-500 mr-2"></div>
                      <span className="text-sm">Advance Payments (Pending)</span>
                    </div>
                    <span className="font-medium">{dashboardData.pendingAdvancePayments}</span>
                  </div>

                  {/* Balance Payments (Pending) */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-2 h-2 rounded-full bg-red-500 mr-2"></div>
                      <span className="text-sm">Balance Payments (Pending)</span>
                    </div>
                    <span className="font-medium">{dashboardData.pendingBalancePayments}</span>
                  </div>

                  {/* Payments Completed */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-2 h-2 rounded-full bg-green-500 mr-2"></div>
                      <span className="text-sm">Payments Completed</span>
                    </div>
                    <span className="font-medium">{dashboardData.completedTrips}</span>
                  </div>

                  <div className="pt-4 mt-4 border-t">
                    <div className="grid grid-cols-2 gap-4">
                      {/* Total Revenue */}
                      <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg">
                        <div className="text-xs text-blue-600 dark:text-blue-400 font-medium uppercase">Total Revenue</div>
                        <div className="text-xl font-bold mt-1 text-blue-700 dark:text-blue-300">
                          {formatCurrency(dashboardData.totalRevenue)}
                        </div>
                      </div>

                      {/* Total Margin */}
                      <div className="bg-green-50 dark:bg-green-900/20 p-4 rounded-lg">
                        <div className="text-xs text-green-600 dark:text-green-400 font-medium uppercase">Total Margin</div>
                        <div className="text-xl font-bold mt-1 text-green-700 dark:text-green-300">
                          {formatCurrency(dashboardData.totalMargin)}
                        </div>
                        <div className="text-sm font-medium mt-1 text-green-600 dark:text-green-400">
                          {calculateMarginPercentage(dashboardData.totalRevenue, dashboardData.totalMargin)} of revenue
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Entities Summary */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Clients */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">Clients</CardTitle>
                  <UsersRound className="h-4 w-4 text-indigo-500" />
                </CardHeader>
                <CardContent className="pb-2">
                  <div className="text-2xl font-bold">{dashboardData.totalClients}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Onboarded clients
                  </p>
                </CardContent>
                <CardFooter className="pt-0">
                  <Link to="/clients" className="text-sm text-blue-600 hover:text-blue-800 flex items-center">
                    View All Clients <ChevronRight className="h-4 w-4 ml-1" />
                  </Link>
                </CardFooter>
              </Card>

              {/* Suppliers */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">Suppliers</CardTitle>
                  <Building className="h-4 w-4 text-purple-500" />
                </CardHeader>
                <CardContent className="pb-2">
                  <div className="text-2xl font-bold">{dashboardData.totalSuppliers}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Registered suppliers
                  </p>
                </CardContent>
                <CardFooter className="pt-0">
                  <Link to="/suppliers" className="text-sm text-blue-600 hover:text-blue-800 flex items-center">
                    View All Suppliers <ChevronRight className="h-4 w-4 ml-1" />
                  </Link>
                </CardFooter>
              </Card>

              {/* Vehicles */}
              <Card>
                <CardHeader className="flex flex-row items-center justify-between py-3">
                  <CardTitle className="text-sm font-medium">Vehicles</CardTitle>
                  <Truck className="h-4 w-4 text-cyan-500" />
                </CardHeader>
                <CardContent className="pb-2">
                  <div className="text-2xl font-bold">{dashboardData.totalVehicles}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Registered vehicles
                  </p>
                </CardContent>
                <CardFooter className="pt-0">
                  <Link to="/vehicles" className="text-sm text-blue-600 hover:text-blue-800 flex items-center">
                    View All Vehicles <ChevronRight className="h-4 w-4 ml-1" />
                  </Link>
                </CardFooter>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="trips">
            <div className="flex items-center justify-center p-12">
              <div className="text-center">
                <BarChart4 className="h-12 w-12 mx-auto mb-4 text-muted-foreground/80" />
                <h3 className="font-medium text-lg mb-2">Trip Analytics</h3>
                <p className="text-muted-foreground max-w-md mx-auto mb-4">
                  Detailed trip analytics with charts, graphs, and performance metrics will be displayed here.
                </p>
                <Button variant="outline">View Analytics</Button>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="finance">
            <div className="flex items-center justify-center p-12">
              <div className="text-center">
                <PieChart className="h-12 w-12 mx-auto mb-4 text-muted-foreground/80" />
                <h3 className="font-medium text-lg mb-2">Financial Reports</h3>
                <p className="text-muted-foreground max-w-md mx-auto mb-4">
                  Financial reports, revenue charts, and payment analytics will be displayed here.
                </p>
                <Button variant="outline">View Reports</Button>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="performance">
            <div className="flex items-center justify-center p-12">
              <div className="text-center">
                <ArrowUpRight className="h-12 w-12 mx-auto mb-4 text-muted-foreground/80" />
                <h3 className="font-medium text-lg mb-2">Performance Metrics</h3>
                <p className="text-muted-foreground max-w-md mx-auto mb-4">
                  Key performance indicators and system metrics will be displayed here.
                </p>
                <Button variant="outline">View Metrics</Button>
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </MainLayout>
  );
};

export default Dashboard;
