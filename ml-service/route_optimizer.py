import numpy as np
import pandas as pd
import requests
import asyncio
import logging
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from geopy.distance import geodesic
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import joblib
import redis
from datetime import datetime, timedelta
import json

@dataclass
class Location:
    latitude: float
    longitude: float
    address: str = ""
    
@dataclass
class Vehicle:
    id: str
    capacity: float
    fuel_efficiency: float
    current_location: Location
    max_distance: float
    driver_id: str

@dataclass
class Trip:
    id: str
    pickup: Location
    delivery: Location
    weight: float
    priority: int  # 1=highest, 5=lowest
    time_window: Tuple[datetime, datetime]
    estimated_duration: float = 0.0

@dataclass
class OptimizedRoute:
    vehicle_id: str
    trips: List[Trip]
    total_distance: float
    total_duration: float
    fuel_cost: float
    efficiency_score: float
    waypoints: List[Location]

class RouteOptimizer:
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_client = redis.from_url(redis_url)
        self.scaler = StandardScaler()
        self.model = None
        self.logger = logging.getLogger(__name__)
        
        # Load pre-trained models
        self._load_models()
        
        # API keys and configurations
        self.google_maps_api_key = "YOUR_GOOGLE_MAPS_API_KEY"
        self.traffic_api_key = "YOUR_TRAFFIC_API_KEY"
        
    def _load_models(self):
        """Load pre-trained ML models for route optimization."""
        try:
            self.model = joblib.load('models/route_efficiency_model.pkl')
            self.scaler = joblib.load('models/feature_scaler.pkl')
            self.logger.info("Models loaded successfully")
        except FileNotFoundError:
            self.logger.warning("No pre-trained models found. Training new models...")
            self._train_models()
    
    def _train_models(self):
        """Train machine learning models for route optimization."""
        # Generate synthetic training data (in production, use historical data)
        training_data = self._generate_training_data()
        
        features = [
            'distance', 'traffic_factor', 'time_of_day', 'day_of_week',
            'weather_score', 'vehicle_efficiency', 'load_factor', 'priority_score'
        ]
        
        X = training_data[features]
        y = training_data['efficiency_score']
        
        # Scale features
        X_scaled = self.scaler.fit_transform(X)
        
        # Train Random Forest model
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        self.model.fit(X_scaled, y)
        
        # Save models
        joblib.dump(self.model, 'models/route_efficiency_model.pkl')
        joblib.dump(self.scaler, 'models/feature_scaler.pkl')
        
        self.logger.info("Models trained and saved successfully")
    
    def _generate_training_data(self) -> pd.DataFrame:
        """Generate synthetic training data for model training."""
        np.random.seed(42)
        n_samples = 10000
        
        data = {
            'distance': np.random.exponential(50, n_samples),  # km
            'traffic_factor': np.random.beta(2, 2, n_samples),  # 0-1
            'time_of_day': np.random.randint(0, 24, n_samples),  # hour
            'day_of_week': np.random.randint(0, 7, n_samples),  # 0=Monday
            'weather_score': np.random.beta(3, 2, n_samples),  # 0-1 (1=perfect weather)
            'vehicle_efficiency': np.random.normal(15, 3, n_samples),  # km/l
            'load_factor': np.random.beta(2, 2, n_samples),  # 0-1
            'priority_score': np.random.randint(1, 6, n_samples),  # 1-5
        }
        
        df = pd.DataFrame(data)
        
        # Calculate efficiency score based on features
        df['efficiency_score'] = (
            (100 - df['distance'] * 0.5) * df['weather_score'] * 
            (1 - df['traffic_factor'] * 0.3) * df['vehicle_efficiency'] / 20 *
            (1 - df['load_factor'] * 0.2) * (6 - df['priority_score']) / 5
        )
        
        # Normalize efficiency score to 0-100
        df['efficiency_score'] = np.clip(df['efficiency_score'], 0, 100)
        
        return df
    
    async def optimize_routes(
        self, 
        vehicles: List[Vehicle], 
        trips: List[Trip],
        optimization_strategy: str = "balanced"
    ) -> List[OptimizedRoute]:
        """
        Optimize routes for multiple vehicles and trips.
        
        Args:
            vehicles: Available vehicles
            trips: List of trips to be assigned
            optimization_strategy: "fuel_efficient", "time_optimal", "balanced"
        
        Returns:
            List of optimized routes for each vehicle
        """
        self.logger.info(f"Optimizing routes for {len(vehicles)} vehicles and {len(trips)} trips")
        
        # Get real-time traffic data
        traffic_data = await self._get_traffic_data()
        
        # Calculate distance matrix
        distance_matrix = await self._calculate_distance_matrix(vehicles, trips)
        
        # Apply optimization algorithm
        if optimization_strategy == "fuel_efficient":
            routes = await self._optimize_for_fuel_efficiency(vehicles, trips, distance_matrix, traffic_data)
        elif optimization_strategy == "time_optimal":
            routes = await self._optimize_for_time(vehicles, trips, distance_matrix, traffic_data)
        else:  # balanced
            routes = await self._optimize_balanced(vehicles, trips, distance_matrix, traffic_data)
        
        # Calculate route metrics
        optimized_routes = []
        for vehicle_id, assigned_trips in routes.items():
            route = await self._calculate_route_metrics(
                vehicle_id, assigned_trips, distance_matrix, traffic_data
            )
            optimized_routes.append(route)
        
        # Cache results
        await self._cache_optimization_results(optimized_routes)
        
        return optimized_routes
    
    async def _get_traffic_data(self) -> Dict:
        """Fetch real-time traffic data from external APIs."""
        try:
            # Check cache first
            cached_data = self.redis_client.get("traffic_data")
            if cached_data:
                return json.loads(cached_data)
            
            # Simulate traffic API call (replace with actual API)
            traffic_data = {
                "timestamp": datetime.now().isoformat(),
                "average_speed": np.random.normal(45, 10),  # km/h
                "congestion_level": np.random.uniform(0, 1),
                "incidents": []
            }
            
            # Cache for 5 minutes
            self.redis_client.setex(
                "traffic_data", 
                300, 
                json.dumps(traffic_data, default=str)
            )
            
            return traffic_data
            
        except Exception as e:
            self.logger.error(f"Error fetching traffic data: {e}")
            return {"average_speed": 40, "congestion_level": 0.3, "incidents": []}
    
    async def _calculate_distance_matrix(
        self, 
        vehicles: List[Vehicle], 
        trips: List[Trip]
    ) -> Dict[str, Dict[str, float]]:
        """Calculate distance matrix between all locations."""
        locations = []
        
        # Add vehicle locations
        for vehicle in vehicles:
            locations.append(vehicle.current_location)
        
        # Add pickup and delivery locations
        for trip in trips:
            locations.append(trip.pickup)
            locations.append(trip.delivery)
        
        # Remove duplicates
        unique_locations = list({
            (loc.latitude, loc.longitude): loc 
            for loc in locations
        }.values())
        
        # Calculate distance matrix
        matrix = {}
        for i, loc1 in enumerate(unique_locations):
            key1 = f"{loc1.latitude},{loc1.longitude}"
            matrix[key1] = {}
            
            for j, loc2 in enumerate(unique_locations):
                key2 = f"{loc2.latitude},{loc2.longitude}"
                
                if i == j:
                    matrix[key1][key2] = 0.0
                else:
                    # Use geodesic distance (in production, use actual road distance)
                    distance = geodesic(
                        (loc1.latitude, loc1.longitude),
                        (loc2.latitude, loc2.longitude)
                    ).kilometers
                    matrix[key1][key2] = distance
        
        return matrix
    
    async def _optimize_for_fuel_efficiency(
        self, 
        vehicles: List[Vehicle], 
        trips: List[Trip],
        distance_matrix: Dict,
        traffic_data: Dict
    ) -> Dict[str, List[Trip]]:
        """Optimize routes prioritizing fuel efficiency."""
        routes = {vehicle.id: [] for vehicle in vehicles}
        unassigned_trips = trips.copy()
        
        # Sort trips by distance from depot (shortest first)
        for vehicle in vehicles:
            vehicle_key = f"{vehicle.current_location.latitude},{vehicle.current_location.longitude}"
            
            # Calculate distances to all pickup points
            trip_distances = []
            for trip in unassigned_trips:
                pickup_key = f"{trip.pickup.latitude},{trip.pickup.longitude}"
                distance = distance_matrix.get(vehicle_key, {}).get(pickup_key, float('inf'))
                trip_distances.append((distance, trip))
            
            # Sort by distance and assign trips
            trip_distances.sort(key=lambda x: x[0])
            
            current_capacity = 0
            for distance, trip in trip_distances:
                if (current_capacity + trip.weight <= vehicle.capacity and 
                    trip in unassigned_trips):
                    routes[vehicle.id].append(trip)
                    unassigned_trips.remove(trip)
                    current_capacity += trip.weight
        
        return routes
    
    async def _optimize_for_time(
        self, 
        vehicles: List[Vehicle], 
        trips: List[Trip],
        distance_matrix: Dict,
        traffic_data: Dict
    ) -> Dict[str, List[Trip]]:
        """Optimize routes prioritizing delivery time."""
        routes = {vehicle.id: [] for vehicle in vehicles}
        
        # Sort trips by priority and time window
        sorted_trips = sorted(trips, key=lambda t: (t.priority, t.time_window[1]))
        
        for trip in sorted_trips:
            best_vehicle = None
            best_score = float('inf')
            
            for vehicle in vehicles:
                # Calculate insertion cost
                score = await self._calculate_insertion_cost(
                    vehicle, trip, routes[vehicle.id], distance_matrix
                )
                
                if score < best_score:
                    best_score = score
                    best_vehicle = vehicle
            
            if best_vehicle:
                routes[best_vehicle.id].append(trip)
        
        return routes
    
    async def _optimize_balanced(
        self, 
        vehicles: List[Vehicle], 
        trips: List[Trip],
        distance_matrix: Dict,
        traffic_data: Dict
    ) -> Dict[str, List[Trip]]:
        """Optimize routes with balanced approach using ML model."""
        routes = {vehicle.id: [] for vehicle in vehicles}
        
        for trip in trips:
            best_vehicle = None
            best_score = float('-inf')
            
            for vehicle in vehicles:
                # Calculate efficiency score using ML model
                score = await self._predict_route_efficiency(
                    vehicle, trip, routes[vehicle.id], distance_matrix, traffic_data
                )
                
                if score > best_score:
                    best_score = score
                    best_vehicle = vehicle
            
            if best_vehicle:
                routes[best_vehicle.id].append(trip)
        
        return routes
    
    async def _predict_route_efficiency(
        self,
        vehicle: Vehicle,
        trip: Trip,
        current_route: List[Trip],
        distance_matrix: Dict,
        traffic_data: Dict
    ) -> float:
        """Predict route efficiency using ML model."""
        # Calculate features
        vehicle_key = f"{vehicle.current_location.latitude},{vehicle.current_location.longitude}"
        pickup_key = f"{trip.pickup.latitude},{trip.pickup.longitude}"
        
        distance = distance_matrix.get(vehicle_key, {}).get(pickup_key, 0)
        current_load = sum(t.weight for t in current_route)
        load_factor = (current_load + trip.weight) / vehicle.capacity
        
        features = np.array([[
            distance,
            traffic_data.get('congestion_level', 0.3),
            datetime.now().hour,
            datetime.now().weekday(),
            0.8,  # weather_score (placeholder)
            vehicle.fuel_efficiency,
            load_factor,
            trip.priority
        ]])
        
        # Scale features and predict
        features_scaled = self.scaler.transform(features)
        efficiency_score = self.model.predict(features_scaled)[0]
        
        return efficiency_score
    
    async def _calculate_insertion_cost(
        self,
        vehicle: Vehicle,
        trip: Trip,
        current_route: List[Trip],
        distance_matrix: Dict
    ) -> float:
        """Calculate the cost of inserting a trip into current route."""
        # Simple insertion cost calculation
        vehicle_key = f"{vehicle.current_location.latitude},{vehicle.current_location.longitude}"
        pickup_key = f"{trip.pickup.latitude},{trip.pickup.longitude}"
        
        base_distance = distance_matrix.get(vehicle_key, {}).get(pickup_key, 0)
        capacity_penalty = max(0, (sum(t.weight for t in current_route) + trip.weight) - vehicle.capacity) * 1000
        
        return base_distance + capacity_penalty
    
    async def _calculate_route_metrics(
        self,
        vehicle_id: str,
        trips: List[Trip],
        distance_matrix: Dict,
        traffic_data: Dict
    ) -> OptimizedRoute:
        """Calculate comprehensive metrics for an optimized route."""
        total_distance = 0.0
        total_duration = 0.0
        waypoints = []
        
        if not trips:
            return OptimizedRoute(
                vehicle_id=vehicle_id,
                trips=[],
                total_distance=0.0,
                total_duration=0.0,
                fuel_cost=0.0,
                efficiency_score=0.0,
                waypoints=[]
            )
        
        # Calculate route metrics
        current_location = None
        for i, trip in enumerate(trips):
            if i == 0:
                # Distance from vehicle to first pickup
                # This would use the vehicle's current location
                pass
            
            # Add pickup and delivery waypoints
            waypoints.extend([trip.pickup, trip.delivery])
            
            # Calculate distances (simplified)
            pickup_key = f"{trip.pickup.latitude},{trip.pickup.longitude}"
            delivery_key = f"{trip.delivery.latitude},{trip.delivery.longitude}"
            
            trip_distance = distance_matrix.get(pickup_key, {}).get(delivery_key, 0)
            total_distance += trip_distance
            
            # Estimate duration (distance / average_speed)
            avg_speed = traffic_data.get('average_speed', 40)
            total_duration += trip_distance / avg_speed
        
        # Calculate fuel cost (simplified)
        fuel_efficiency = 15  # km/l (would get from vehicle data)
        fuel_price = 100  # per liter (would get from current prices)
        fuel_cost = (total_distance / fuel_efficiency) * fuel_price
        
        # Calculate efficiency score
        efficiency_score = max(0, 100 - (total_distance * 0.5) - (total_duration * 2))
        
        return OptimizedRoute(
            vehicle_id=vehicle_id,
            trips=trips,
            total_distance=total_distance,
            total_duration=total_duration,
            fuel_cost=fuel_cost,
            efficiency_score=efficiency_score,
            waypoints=waypoints
        )
    
    async def _cache_optimization_results(self, routes: List[OptimizedRoute]):
        """Cache optimization results for quick access."""
        cache_data = {
            "timestamp": datetime.now().isoformat(),
            "routes": [
                {
                    "vehicle_id": route.vehicle_id,
                    "trip_count": len(route.trips),
                    "total_distance": route.total_distance,
                    "total_duration": route.total_duration,
                    "fuel_cost": route.fuel_cost,
                    "efficiency_score": route.efficiency_score
                }
                for route in routes
            ]
        }
        
        self.redis_client.setex(
            "latest_optimization", 
            3600,  # 1 hour
            json.dumps(cache_data, default=str)
        )
    
    async def get_route_suggestions(
        self, 
        vehicle_id: str, 
        current_location: Location
    ) -> Dict:
        """Get real-time route suggestions for a specific vehicle."""
        # Get traffic updates
        traffic_data = await self._get_traffic_data()
        
        # Check for route alternatives
        suggestions = {
            "traffic_alerts": [],
            "alternative_routes": [],
            "estimated_savings": {}
        }
        
        if traffic_data.get('congestion_level', 0) > 0.7:
            suggestions["traffic_alerts"].append(
                "High traffic detected. Consider alternative route."
            )
        
        return suggestions
    
    def get_optimization_metrics(self) -> Dict:
        """Get overall optimization performance metrics."""
        cached_data = self.redis_client.get("latest_optimization")
        if not cached_data:
            return {"error": "No recent optimization data available"}
        
        data = json.loads(cached_data)
        routes = data["routes"]
        
        metrics = {
            "total_routes": len(routes),
            "average_efficiency": np.mean([r["efficiency_score"] for r in routes]),
            "total_distance": sum(r["total_distance"] for r in routes),
            "total_fuel_cost": sum(r["fuel_cost"] for r in routes),
            "optimization_timestamp": data["timestamp"]
        }
        
        return metrics

# FastAPI endpoints for the service
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="AI Route Optimizer", version="1.0.0")
optimizer = RouteOptimizer()

class OptimizationRequest(BaseModel):
    vehicles: List[Dict]
    trips: List[Dict]
    strategy: str = "balanced"

@app.post("/optimize-routes")
async def optimize_routes_endpoint(request: OptimizationRequest):
    """Optimize routes for given vehicles and trips."""
    try:
        # Convert dictionaries to dataclasses
        vehicles = [Vehicle(**v) for v in request.vehicles]
        trips = [Trip(**t) for t in request.trips]
        
        routes = await optimizer.optimize_routes(vehicles, trips, request.strategy)
        
        return {
            "status": "success",
            "routes": [route.__dict__ for route in routes],
            "metrics": optimizer.get_optimization_metrics()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/route-suggestions/{vehicle_id}")
async def get_route_suggestions_endpoint(vehicle_id: str, lat: float, lng: float):
    """Get real-time route suggestions for a vehicle."""
    try:
        location = Location(latitude=lat, longitude=lng)
        suggestions = await optimizer.get_route_suggestions(vehicle_id, location)
        return suggestions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics")
async def get_metrics_endpoint():
    """Get optimization performance metrics."""
    return optimizer.get_optimization_metrics()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 