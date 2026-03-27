import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { GoogleMap, Polyline, Marker, useJsApiLoader } from '@react-google-maps/api';

type TrackedUser = {
  id: string;
  name: string;
  status: string;
  lastCheckInTime?: string;
  batteryLevel?: number;
  deviceOnline: boolean;
  lastLocation?: { lat: number; lng: number };
  path: { lat: number; lng: number }[];
};

const PARSE_APP_ID = import.meta.env.VITE_PARSE_APP_ID;
const PARSE_REST_KEY = import.meta.env.VITE_PARSE_REST_KEY;
const PARSE_SERVER_URL = import.meta.env.VITE_PARSE_SERVER_URL;

const MAPS_KEY = import.meta.env.VITE_GOOGLE_MAPS_KEY as string;

export const App: React.FC = () => {
  const [users, setUsers] = useState<TrackedUser[]>([]);
  const [loading, setLoading] = useState(true);
  const { isLoaded } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: MAPS_KEY || '',
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await axios.get(`${PARSE_SERVER_URL}/classes/User`, {
          headers: {
            'X-Parse-Application-Id': PARSE_APP_ID,
            'X-Parse-REST-API-Key': PARSE_REST_KEY,
          },
          params: {
            where: JSON.stringify({ protectionModeActive: true }),
            include: 'lastKnownLocation',
          },
        });
        const results = res.data.results as any[];
        const mapped: TrackedUser[] = [];
        for (const u of results) {
          const trailRes = await axios.get(
            `${PARSE_SERVER_URL}/classes/RiskLocationTrail`,
            {
              headers: {
                'X-Parse-Application-Id': PARSE_APP_ID,
                'X-Parse-REST-API-Key': PARSE_REST_KEY,
              },
              params: {
                where: JSON.stringify({ userId: u.objectId }),
                order: 'createdAt',
              },
            },
          );
          const path =
            (trailRes.data.results as any[]).map((t) => ({
              lat: t.location.latitude,
              lng: t.location.longitude,
            })) ?? [];

          mapped.push({
            id: u.objectId,
            name: u.name ?? 'User',
            status: u.status ?? 'SAFE',
            lastCheckInTime: u.lastCheckInTime,
            batteryLevel: u.batteryLevel,
            deviceOnline: u.deviceOnline ?? true,
            lastLocation: u.lastKnownLocation
              ? {
                  lat: u.lastKnownLocation.latitude,
                  lng: u.lastKnownLocation.longitude,
                }
              : undefined,
            path,
          });
        }
        setUsers(mapped);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const id = setInterval(fetchData, 15000);
    return () => clearInterval(id);
  }, []);

  const center =
    users.find((u) => u.lastLocation)?.lastLocation ?? { lat: 0, lng: 0 };

  return (
    <div style={{ display: 'flex', height: '100vh', fontFamily: 'system-ui' }}>
      <div style={{ width: 320, borderRight: '1px solid #eee', padding: 16 }}>
        <h2>Guardian-Paws</h2>
        <p style={{ color: '#666' }}>Real-time safety dashboard</p>
        {loading && <p>Loading...</p>}
        <div style={{ marginTop: 16, overflowY: 'auto', maxHeight: '80vh' }}>
          {users.map((u) => (
            <div
              key={u.id}
              style={{
                border: '1px solid #eee',
                borderRadius: 12,
                padding: 12,
                marginBottom: 8,
                background: '#fafafa',
              }}
            >
              <div style={{ fontWeight: 600 }}>{u.name}</div>
              <div
                style={{
                  fontSize: 12,
                  marginTop: 4,
                  color: u.status === 'SAFE' ? '#1b8d3a' : '#c0392b',
                }}
              >
                Status: {u.status}
              </div>
              <div style={{ fontSize: 12, marginTop: 4 }}>
                Last confirmation:{' '}
                {u.lastCheckInTime ? new Date(u.lastCheckInTime).toLocaleString() : 'Never'}
              </div>
              <div style={{ fontSize: 12, marginTop: 4 }}>
                Battery:{' '}
                {u.batteryLevel !== undefined
                  ? `${u.batteryLevel.toFixed(0)}%`
                  : 'Unknown'}
              </div>
              <div
                style={{
                  fontSize: 12,
                  marginTop: 4,
                  color: u.deviceOnline ? '#1b8d3a' : '#c0392b',
                }}
              >
                Device: {u.deviceOnline ? 'Online' : 'Offline'}
              </div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ flex: 1 }}>
        {isLoaded && (
          <GoogleMap
            mapContainerStyle={{ width: '100%', height: '100%' }}
            center={center}
            zoom={center.lat === 0 && center.lng === 0 ? 2 : 14}
          >
            {users.map(
              (u) =>
                u.lastLocation && (
                  <Marker
                    key={u.id}
                    position={u.lastLocation}
                    label={u.name}
                  />
                ),
            )}
            {users.map(
              (u) =>
                u.path.length > 1 && (
                  <Polyline
                    key={`p-${u.id}`}
                    path={u.path}
                    options={{
                      strokeColor: '#e74c3c',
                      strokeOpacity: 0.9,
                      strokeWeight: 4,
                    }}
                  />
                ),
            )}
          </GoogleMap>
        )}
      </div>
    </div>
  );
};

