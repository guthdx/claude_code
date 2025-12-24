export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface Landmark {
  id: string;
  name: string;
  coords: Coordinates;
  radius: number; // in meters
  lastTriggered: number | null; // timestamp
}

export interface Schedule {
  id: string;
  time: string; // HH:mm format (24h)
  label: string;
  lastTriggeredDate: string | null; // ISO date string (YYYY-MM-DD)
}

export interface Quote {
  text: string;
  interpretation: string;
  context: string;
  timestamp: number;
}

export enum AppView {
  HOME = 'HOME',
  LANDMARKS = 'LANDMARKS',
  SCHEDULES = 'SCHEDULES',
}