import { Router, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';

const router = Router();
const DATA_FILE_PATH = path.join(__dirname, '../../data/smartbus_state.json');
const ADMIN_HTML_PATH = path.join(__dirname, '../../data/admin.html');

interface TimetableEntry {
  stop?: string;
  stopName?: string;
  time: string;
}

interface BusWorkers {
  driver?: string;
  driverPhone?: string;
  conductor?: string;
  conductorPhone?: string;
  cleaner?: string;
  cleanerPhone?: string;
}

interface BusRecord {
  regNumber: string;
  busName: string;
  category: string;
  route: string;
  startPoint: string;
  destPoint: string;
  seatingCapacity: number;
  isTripActive: boolean;
  status: string;
  todayCollection: number;
  ticketsSold?: number;
  ticketsCount?: number;
  workers?: BusWorkers;
  driverName?: string;
  driverPhone?: string;
  conductorName?: string;
  conductorPhone?: string;
  conductorEmail?: string;
  cleanerName?: string;
  cleanerPhone?: string;
  ownerName?: string;
  ownerPhone?: string;
  ownerEmail?: string;
  companyName?: string;
  timetable?: TimetableEntry[];
  stops?: any[];
  verificationStatus?: string;
  isApprovedByAdmin?: boolean;
  chassisNumber?: string;
  permitNumber?: string;
  fitnessValidity?: string;
  insurancePolicyNumber?: string;
  currentStop?: string;
  nextStop?: string;
  eta?: string;
  isLiveGpsActive?: boolean;
  currentLatitude?: number;
  currentLongitude?: number;
  conductorLocationString?: string;
  customFareChart?: Record<string, number>;
  [key: string]: any;
}

// Initial baseline seed data
const initialSeedData = {
  project: 'EnRoute',
  version: '1.0.0',
  environment: 'development',
  databaseEngine: 'JSON File Persistence & PostgreSQL Dual Layer',
  owner: {
    id: 'OWNER-1',
    fullName: 'Sahl',
    email: 'sahl@gmail.com',
    phoneNumber: '+91 94470 12345',
    operatorName: 'Sahl Motors Kozhikode',
    isVerified: true,
  },
  owners: [
    {
      id: 'OWNER-1',
      fullName: 'Sahl',
      email: 'sahl@gmail.com',
      phoneNumber: '+91 94470 12345',
      operatorName: 'Sahl Motors Kozhikode',
      isVerified: true,
    },
    {
      id: 'OWNER-2',
      fullName: 'Fathima Riyas',
      email: 'fathima.owner@gmail.com',
      phoneNumber: '+91 94470 54321',
      operatorName: 'Fathima Riyas Transit',
      isVerified: true,
    },
  ],
  passengers: [
    {
      id: 'SBK-KL-987263',
      fullName: 'Fathima',
      email: 'fathima@gmail.com',
      phoneNumber: '+91 98470 00004',
      walletBalance: 250.0,
      concessionCategory: 'General / Adult Standard',
      homeStation: 'Kozhikkode Stand',
      status: 'ACTIVE',
      registeredAt: '2026-10-01T00:00:00.000Z',
    },
    {
      id: 'SBK-KL-554120',
      fullName: 'Adhil KM',
      email: 'adhil@gmail.com',
      phoneNumber: '+91 98470 00005',
      walletBalance: 120.0,
      concessionCategory: 'Student Concession (₹5 Flat Tariff)',
      homeStation: 'Mannarkad Stand',
      status: 'ACTIVE',
      registeredAt: '2026-10-05T00:00:00.000Z',
    },
    {
      id: 'SBK-KL-339811',
      fullName: 'Kp',
      email: 'kp@gmail.com',
      phoneNumber: '+91 98470 00006',
      walletBalance: 450.0,
      concessionCategory: 'General / Adult Standard',
      homeStation: 'Farook College',
      status: 'ACTIVE',
      registeredAt: '2026-10-08T00:00:00.000Z',
    },
  ],
  conductors: [
    {
      id: 'COND-1',
      fullName: 'Shamil K',
      userId: 'shamil.conductor',
      phoneNumber: '+91 98470 11001',
      licenseNumber: 'KL-10-COND-2018-8891',
      assignedBusReg: 'KL 10 AZ 4589',
      assignedBusName: 'Sana',
      role: 'ROLE_CONDUCTOR',
      status: 'ACTIVE',
    },
    {
      id: 'COND-2',
      fullName: 'Kaarangadan',
      userId: 'kaarangadan.conductor',
      phoneNumber: '+91 98470 11002',
      licenseNumber: 'KL-10-COND-2020-4102',
      assignedBusReg: 'KL 10 CE 1204',
      assignedBusName: 'Arafa',
      role: 'ROLE_CONDUCTOR',
      status: 'ACTIVE',
    },
    {
      id: 'COND-3',
      fullName: 'Anfal',
      userId: 'anfal.conductor',
      phoneNumber: '+91 98470 11003',
      licenseNumber: 'KL-11-COND-2021-7740',
      assignedBusReg: 'KL 11 BQ 9981',
      assignedBusName: 'Sanha',
      role: 'ROLE_CONDUCTOR',
      status: 'ACTIVE',
    },
    {
      id: 'COND-4',
      fullName: 'Jamsheer',
      userId: 'jamsheer.conductor',
      phoneNumber: '+91 98470 11004',
      licenseNumber: 'KL-11-COND-2022-5509',
      assignedBusReg: 'KL 11 CF 3320',
      assignedBusName: 'KKB',
      role: 'ROLE_CONDUCTOR',
      status: 'ACTIVE',
    },
  ],
  buses: [
    {
      regNumber: 'KL 10 AZ 4589',
      busName: 'Sana',
      category: 'Limited Stop Bus (Red-Whiteline)',
      route: 'Mannarkad Stand ➔ Kozhikkode Stand (via Manjeri & Kondotty)',
      startPoint: 'Mannarkad',
      destPoint: 'Kozhikkode',
      seatingCapacity: 48,
      isTripActive: false,
      status: 'STOPPED / DEPOT',
      todayCollection: 6420.0,
      ticketsSold: 168,
      ownerName: 'Sahl',
      ownerPhone: '+91 94470 12345',
      ownerEmail: 'sahl@gmail.com',
      companyName: 'Sahl Motors Kozhikode',
      driverName: 'Venu Pillai (Badge #KL4201)',
      driverPhone: '+91 94470 55112',
      conductorName: 'Shamil K',
      conductorPhone: '+91 98470 11001',
      cleanerName: 'Mani K.',
      cleanerPhone: '+91 94470 55113',
      chassisNumber: 'MB1-420-KL-CHASSIS-8891',
      permitNumber: 'KL/2026/MVD/STAGE/0491',
      fitnessValidity: '28-Dec-2027',
      insurancePolicyNumber: 'NIC-KL-COM-778210',
      verificationStatus: 'ADMIN_APPROVED',
      isApprovedByAdmin: true,
      workers: {
        driver: 'Venu Pillai (Badge #KL4201)',
        conductor: 'Shamil K',
        cleaner: 'Mani K.',
      },
      timetable: [
        { stop: 'Mannarkad Stand', time: '07:00 AM' },
        { stop: 'Alanallur', time: '07:25 AM' },
        { stop: 'Melattur', time: '07:45 AM' },
        { stop: 'Pandikkad', time: '08:05 AM' },
        { stop: 'Manjeri Stand', time: '08:35 AM' },
        { stop: 'Kondotty', time: '09:05 AM' },
        { stop: 'Ramanattukara', time: '09:30 AM' },
        { stop: 'Kozhikkode Stand', time: '10:00 AM' },
      ],
      currentLatitude: 10.9882,
      currentLongitude: 76.4589,
      conductorLocationString: 'Mannarkad Stand Depot (Resting)',
    },
    {
      regNumber: 'KL 10 CE 1204',
      busName: 'Arafa',
      category: 'Ordinary Bus (Blue-Whiteline)',
      route: 'Kalikavu Stand ➔ Kozhikkode Stand (via Wandoor & Manjeri)',
      startPoint: 'Kalikavu',
      destPoint: 'Kozhikkode',
      seatingCapacity: 52,
      isTripActive: false,
      status: 'STOPPED / DEPOT',
      todayCollection: 7840.0,
      ticketsSold: 202,
      ownerName: 'Sahl',
      ownerPhone: '+91 94470 12345',
      ownerEmail: 'sahl@gmail.com',
      companyName: 'Sahl Motors Kozhikode',
      driverName: 'Antony Joseph',
      driverPhone: '+91 94470 55114',
      conductorName: 'Kaarangadan',
      conductorPhone: '+91 98470 11002',
      cleanerName: 'Saji T.',
      cleanerPhone: '+91 94470 55115',
      chassisNumber: 'MB1-420-KL-CHASSIS-9922',
      permitNumber: 'KL/2026/MVD/STAGE/0512',
      fitnessValidity: '15-Nov-2027',
      insurancePolicyNumber: 'UI-KL-COM-883901',
      verificationStatus: 'ADMIN_APPROVED',
      isApprovedByAdmin: true,
      workers: {
        driver: 'Antony Joseph',
        conductor: 'Kaarangadan',
        cleaner: 'Saji T.',
      },
      timetable: [
        { stop: 'Kalikavu Stand', time: '07:30 AM' },
        { stop: 'Wandoor', time: '07:55 AM' },
        { stop: 'Edavanna', time: '08:15 AM' },
        { stop: 'Manjeri Stand', time: '08:40 AM' },
        { stop: 'Kondotty', time: '09:10 AM' },
        { stop: 'Ramanattukara', time: '09:35 AM' },
        { stop: 'Kozhikkode Stand', time: '10:05 AM' },
      ],
      currentLatitude: 11.1738,
      currentLongitude: 76.3268,
      conductorLocationString: 'Kalikavu Stand Depot (Resting)',
    },
    {
      regNumber: 'KL 11 BQ 9981',
      busName: 'Sanha',
      category: 'City Bus (Green-Whiteline)',
      route: 'Farook College ➔ West Hill (via Palayam & Mananchira)',
      startPoint: 'Farook College',
      destPoint: 'West Hill',
      seatingCapacity: 48,
      isTripActive: false,
      status: 'STOPPED / DEPOT',
      todayCollection: 4220.0,
      ticketsSold: 116,
      ownerName: 'Fathima Riyas',
      ownerPhone: '+91 94470 54321',
      ownerEmail: 'fathima.owner@gmail.com',
      companyName: 'Fathima Riyas Transit',
      driverName: 'Pradeep Kumar',
      driverPhone: '+91 94470 55116',
      conductorName: 'Anfal',
      conductorPhone: '+91 98470 11003',
      cleanerName: 'Babu N.',
      cleanerPhone: '+91 94470 55117',
      chassisNumber: 'MB1-420-KL-CHASSIS-1104',
      permitNumber: 'KL/2026/MVD/STAGE/0688',
      fitnessValidity: '10-Oct-2027',
      insurancePolicyNumber: 'OIC-KL-COM-991204',
      verificationStatus: 'ADMIN_APPROVED',
      isApprovedByAdmin: true,
      workers: {
        driver: 'Pradeep Kumar',
        conductor: 'Anfal',
        cleaner: 'Babu N.',
      },
      timetable: [
        { stop: 'Farook College', time: '08:00 AM' },
        { stop: 'Feroke Stand', time: '08:15 AM' },
        { stop: 'Meenchanda', time: '08:30 AM' },
        { stop: 'Kallayi', time: '08:42 AM' },
        { stop: 'Palayam Stand', time: '08:55 AM' },
        { stop: 'Mananchira', time: '09:05 AM' },
        { stop: 'Nadakkavu', time: '09:18 AM' },
        { stop: 'West Hill', time: '09:30 AM' },
      ],
      currentLatitude: 11.1895,
      currentLongitude: 75.8505,
      conductorLocationString: 'Farook College Depot (Resting)',
    },
    {
      regNumber: 'KL 11 CF 3320',
      busName: 'KKB',
      category: 'Ordinary Bus (Blue-Whiteline)',
      route: 'Ramanattukara Stand ➔ Kondotty Stand (via Airport Junction)',
      startPoint: 'Ramanattukara',
      destPoint: 'Kondotty',
      seatingCapacity: 44,
      isTripActive: false,
      status: 'STOPPED / DEPOT',
      todayCollection: 3150.0,
      ticketsSold: 98,
      ownerName: 'Sahl',
      ownerPhone: '+91 94470 12345',
      ownerEmail: 'sahl@gmail.com',
      companyName: 'Sahl Motors Kozhikode',
      driverName: 'Santhosh M.',
      driverPhone: '+91 94470 55118',
      conductorName: 'Jamsheer',
      conductorPhone: '+91 98470 11004',
      cleanerName: 'Vijayan T.',
      cleanerPhone: '+91 94470 55119',
      chassisNumber: 'MB1-420-KL-CHASSIS-3320',
      permitNumber: 'KL/2026/MVD/STAGE/0721',
      fitnessValidity: '19-Jan-2028',
      insurancePolicyNumber: 'NIC-KL-COM-889104',
      verificationStatus: 'ADMIN_APPROVED',
      isApprovedByAdmin: true,
      workers: {
        driver: 'Santhosh M.',
        conductor: 'Jamsheer',
        cleaner: 'Vijayan T.',
      },
      timetable: [
        { stop: 'Ramanattukara Stand', time: '08:30 AM' },
        { stop: 'University / Thenhipalam', time: '08:45 AM' },
        { stop: 'Calicut Airport Junction', time: '09:00 AM' },
        { stop: 'Kondotty Stand', time: '09:20 AM' },
      ],
      currentLatitude: 11.1748,
      currentLongitude: 75.8643,
      conductorLocationString: 'Ramanattukara Stand Depot (Resting)',
    },
  ] as BusRecord[],
  tickets: [] as any[],
};

// State loader & persistence helper
function loadState(): typeof initialSeedData {
  try {
    if (fs.existsSync(DATA_FILE_PATH)) {
      const raw = fs.readFileSync(DATA_FILE_PATH, 'utf-8');
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.buses)) {
        return parsed;
      }
    }
  } catch (err) {
    console.error('Failed to read data file, using seed:', err);
  }
  saveState(initialSeedData);
  return initialSeedData;
}

function saveState(data: typeof initialSeedData): void {
  try {
    const dir = path.dirname(DATA_FILE_PATH);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(DATA_FILE_PATH, JSON.stringify(data, null, 2), 'utf-8');
  } catch (err) {
    console.error('Failed to save data file:', err);
  }
}

// -----------------------------------------------------------------------------
// 1. JSON & SYNCHRONIZATION ENDPOINTS
// -----------------------------------------------------------------------------

router.get('/json', (req: Request, res: Response) => {
  const data = loadState();
  const pendingApprovals = data.buses.filter(
    (b) => b.verificationStatus === 'WAITING_FOR_VERIFICATION' || b.isApprovedByAdmin === false
  );
  res.status(200).json({
    ...data,
    summary: {
      totalPassengers: data.passengers.length,
      totalBuses: data.buses.length,
      pendingApprovals: pendingApprovals.length,
      totalConductors: data.conductors.length,
      totalTickets: data.tickets.length,
      activeBuses: data.buses.filter((b) => b.isTripActive).length,
    },
  });
});

/**
 * Bidirectional Sync with Frontend Flutter State
 */
router.post('/sync', (req: Request, res: Response) => {
  const incoming = req.body;
  const current = loadState();

  // Merge passengers
  if (Array.isArray(incoming.passengers)) {
    for (const p of incoming.passengers) {
      const idx = current.passengers.findIndex((item) => item.id === p.id);
      if (idx !== -1) {
        current.passengers[idx] = { ...current.passengers[idx], ...p };
      } else {
        current.passengers.push(p);
      }
    }
  }

  // Handle explicit deletions
  if (Array.isArray(incoming.deletedBusRegs)) {
    const deletedSet = new Set(incoming.deletedBusRegs.map((r: string) => r.toUpperCase()));
    current.buses = current.buses.filter((b) => !deletedSet.has(b.regNumber.toUpperCase()));
  }
  if (Array.isArray(incoming.deletedConductorIds)) {
    const deletedCondSet = new Set(incoming.deletedConductorIds);
    current.conductors = current.conductors.filter((c) => !deletedCondSet.has(c.id));
  }

  // Merge buses
  if (Array.isArray(incoming.buses)) {
    for (const b of incoming.buses) {
      const idx = current.buses.findIndex(
        (item) => item.regNumber.toUpperCase() === b.regNumber.toUpperCase()
      );
      if (idx !== -1) {
        // Protect server-side approval: if already approved by admin, preserve it
        const currentApproved =
          (current.buses[idx] as any).verificationStatus === 'ADMIN_APPROVED' ||
          (current.buses[idx] as any).isApprovedByAdmin === true;
        current.buses[idx] = {
          ...current.buses[idx],
          ...b,
          verificationStatus: currentApproved
            ? 'ADMIN_APPROVED'
            : (b.verificationStatus || (current.buses[idx] as any).verificationStatus || 'ADMIN_APPROVED'),
          isApprovedByAdmin: currentApproved
            ? true
            : (b.isApprovedByAdmin ?? (current.buses[idx] as any).isApprovedByAdmin ?? true),
        };
      } else {
        current.buses.push(b);
      }
    }
  }

  // Merge conductors
  if (Array.isArray(incoming.conductors)) {
    for (const c of incoming.conductors) {
      const idx = current.conductors.findIndex((item) => item.id === c.id || item.userId === c.userId);
      if (idx !== -1) {
        current.conductors[idx] = { ...current.conductors[idx], ...c };
      } else {
        current.conductors.push(c);
      }
    }
  }

  // Merge tickets
  if (Array.isArray(incoming.tickets)) {
    for (const t of incoming.tickets) {
      if (!current.tickets.some((item) => item.id === t.id || item.ticketNumber === t.ticketNumber)) {
        current.tickets.unshift(t);
      }
    }
  }

  saveState(current);
  res.status(200).json({ status: 'success', message: 'Backend data synchronized successfully', data: current });
});

// -----------------------------------------------------------------------------
// 2. PASSENGER CRUD ENDPOINTS
// -----------------------------------------------------------------------------

router.post('/passengers', (req: Request, res: Response) => {
  const data = loadState();
  const { fullName, email, phoneNumber, walletBalance, concessionCategory, homeStation } = req.body;

  if (!fullName || !email) {
    return res.status(400).json({ status: 'error', message: 'Full name and email are required' });
  }

  const newId = `SBK-KL-${Math.floor(100000 + Math.random() * 900000)}`;
  const newPassenger = {
    id: newId,
    fullName: fullName.trim(),
    email: email.trim(),
    phoneNumber: phoneNumber ? phoneNumber.trim() : `+91 98470 ${Math.floor(10000 + Math.random() * 90000)}`,
    walletBalance: Number(walletBalance) || 0.0,
    concessionCategory: concessionCategory || 'General / Adult Standard',
    homeStation: homeStation || 'Aluva Stand, Ernakulam',
    status: 'ACTIVE',
    registeredAt: new Date().toISOString(),
  };

  data.passengers.push(newPassenger);
  saveState(data);
  res.status(201).json({ status: 'success', message: 'Passenger created', data: newPassenger });
});

router.put('/passengers/:id', (req: Request, res: Response) => {
  const data = loadState();
  const id = req.params.id;
  const idx = data.passengers.findIndex((p) => p.id === id);

  if (idx === -1) {
    return res.status(404).json({ status: 'error', message: `Passenger with ID ${id} not found` });
  }

  const p = data.passengers[idx];
  data.passengers[idx] = {
    ...p,
    fullName: req.body.fullName !== undefined ? req.body.fullName.trim() : p.fullName,
    email: req.body.email !== undefined ? req.body.email.trim() : p.email,
    phoneNumber: req.body.phoneNumber !== undefined ? req.body.phoneNumber.trim() : p.phoneNumber,
    walletBalance: req.body.walletBalance !== undefined ? Number(req.body.walletBalance) : p.walletBalance,
    concessionCategory: req.body.concessionCategory || p.concessionCategory,
    homeStation: req.body.homeStation || p.homeStation,
    status: req.body.status || p.status,
  };

  saveState(data);
  res.status(200).json({ status: 'success', message: 'Passenger updated', data: data.passengers[idx] });
});

router.delete('/passengers/:id', (req: Request, res: Response) => {
  const data = loadState();
  const id = req.params.id;
  const beforeCount = data.passengers.length;
  data.passengers = data.passengers.filter((p) => p.id !== id);

  if (data.passengers.length === beforeCount) {
    return res.status(404).json({ status: 'error', message: `Passenger ${id} not found` });
  }

  saveState(data);
  res.status(200).json({ status: 'success', message: `Passenger ${id} deleted successfully` });
});

// -----------------------------------------------------------------------------
// 3. BUS CRUD & ADMIN APPROVAL ENDPOINTS
// -----------------------------------------------------------------------------

router.post('/buses', (req: Request, res: Response) => {
  const data = loadState();
  const {
    regNumber,
    busName,
    category,
    route,
    startPoint,
    destPoint,
    seatingCapacity,
    workers,
    timetable,
    ownerName,
    ownerPhone,
    ownerEmail,
    chassisNumber,
    permitNumber,
    fitnessValidity,
    insurancePolicyNumber,
    verificationStatus,
    isApprovedByAdmin,
  } = req.body;

  if (!regNumber || !busName) {
    return res.status(400).json({ status: 'error', message: 'regNumber and busName are required' });
  }

  const cleanReg = regNumber.trim().toUpperCase();
  if (data.buses.some((b) => b.regNumber.toUpperCase() === cleanReg)) {
    return res.status(409).json({ status: 'error', message: `Bus with registration ${cleanReg} already exists` });
  }

  const newBus: BusRecord = {
    regNumber: cleanReg,
    busName: busName.trim(),
    category: category || 'Ordinary Bus (Blue-Whiteline)',
    route: route || `${startPoint || 'Aluva Stand'} ➔ ${destPoint || 'Perumbavoor Stand'}`,
    startPoint: startPoint || 'Aluva Stand',
    destPoint: destPoint || 'Perumbavoor Stand',
    seatingCapacity: Number(seatingCapacity) || 48,
    isTripActive: false,
    status: 'STOPPED / DEPOT',
    todayCollection: 0.0,
    ticketsSold: 0,
    ownerName: ownerName || 'George Varghese',
    ownerPhone: ownerPhone || '+91 94470 12345',
    ownerEmail: ownerEmail || 'owner@stgeorge.com',
    chassisNumber: chassisNumber || `MB1-KL-CHASSIS-${Math.floor(1000 + Math.random() * 9000)}`,
    permitNumber: permitNumber || `KL/2026/MVD/STAGE/${Math.floor(1000 + Math.random() * 9000)}`,
    fitnessValidity: fitnessValidity || '31-Dec-2027',
    insurancePolicyNumber: insurancePolicyNumber || `NIC-KL-COM-${Math.floor(100000 + Math.random() * 900000)}`,
    verificationStatus: verificationStatus || 'WAITING_FOR_VERIFICATION',
    isApprovedByAdmin: isApprovedByAdmin !== undefined ? Boolean(isApprovedByAdmin) : false,
    workers: workers || { driver: 'Assigned Driver', conductor: 'Assigned Conductor', cleaner: 'Assigned Cleaner' },
    timetable:
      Array.isArray(timetable) && timetable.length > 0
        ? timetable
        : [
            { stop: startPoint || 'Aluva Stand', time: '08:00 AM' },
            { stop: destPoint || 'Perumbavoor Stand', time: '09:00 AM' },
          ],
  };

  data.buses.push(newBus);
  saveState(data);
  res.status(201).json({ status: 'success', message: 'Bus registered', data: newBus });
});

router.put('/buses/:regNumber', (req: Request, res: Response) => {
  const data = loadState();
  const cleanReg = req.params.regNumber.trim().toUpperCase();
  const idx = data.buses.findIndex((b) => b.regNumber.toUpperCase() === cleanReg);

  if (idx === -1) {
    return res.status(404).json({ status: 'error', message: `Bus ${cleanReg} not found` });
  }

  const b = data.buses[idx];
  data.buses[idx] = {
    ...b,
    busName: req.body.busName !== undefined ? req.body.busName.trim() : b.busName,
    category: req.body.category || b.category,
    route: req.body.route || b.route,
    startPoint: req.body.startPoint || b.startPoint,
    destPoint: req.body.destPoint || b.destPoint,
    seatingCapacity: req.body.seatingCapacity !== undefined ? Number(req.body.seatingCapacity) : b.seatingCapacity,
    isTripActive: req.body.isTripActive !== undefined ? Boolean(req.body.isTripActive) : b.isTripActive,
    status: req.body.status || (req.body.isTripActive ? 'RUNNING_NOW' : 'STOPPED / DEPOT'),
    workers: req.body.workers ? { ...b.workers, ...req.body.workers } : b.workers,
    timetable: req.body.timetable || b.timetable,
    driverName: req.body.driverName || b.driverName,
    driverPhone: req.body.driverPhone || b.driverPhone,
    cleanerName: req.body.cleanerName || b.cleanerName,
    cleanerPhone: req.body.cleanerPhone || b.cleanerPhone,
    conductorName: req.body.conductorName || b.conductorName,
    conductorPhone: req.body.conductorPhone || b.conductorPhone,
    chassisNumber: req.body.chassisNumber || b.chassisNumber,
    permitNumber: req.body.permitNumber || b.permitNumber,
    fitnessValidity: req.body.fitnessValidity || b.fitnessValidity,
    insurancePolicyNumber: req.body.insurancePolicyNumber || b.insurancePolicyNumber,
    ownerName: req.body.ownerName || b.ownerName,
    ownerPhone: req.body.ownerPhone || b.ownerPhone,
    currentLatitude: req.body.currentLatitude !== undefined ? Number(req.body.currentLatitude) : b.currentLatitude,
    currentLongitude: req.body.currentLongitude !== undefined ? Number(req.body.currentLongitude) : b.currentLongitude,
    isLiveGpsActive: req.body.isLiveGpsActive !== undefined ? Boolean(req.body.isLiveGpsActive) : b.isLiveGpsActive,
    conductorLocationString: req.body.conductorLocationString || b.conductorLocationString,
    currentStop: req.body.currentStop || b.currentStop,
    nextStop: req.body.nextStop || b.nextStop,
    eta: req.body.eta || b.eta,
  };

  saveState(data);
  res.status(200).json({ status: 'success', message: 'Bus updated', data: data.buses[idx] });
});

// Fast real-time location update endpoint for active buses
router.post('/bus-location', (req: Request, res: Response) => {
  const data = loadState();
  const { regNumber, latitude, longitude, speed, locationString, isLiveGpsActive, currentStop, nextStop, eta } = req.body;
  if (!regNumber) {
    return res.status(400).json({ status: 'error', message: 'regNumber is required' });
  }

  const cleanReg = regNumber.trim().toUpperCase();
  const idx = data.buses.findIndex((b) => b.regNumber.toUpperCase() === cleanReg);
  if (idx === -1) {
    return res.status(404).json({ status: 'error', message: `Bus ${cleanReg} not found` });
  }

  if (latitude !== undefined) data.buses[idx].currentLatitude = Number(latitude);
  if (longitude !== undefined) data.buses[idx].currentLongitude = Number(longitude);
  if (speed !== undefined) (data.buses[idx] as any).speed = Number(speed);
  if (locationString) data.buses[idx].conductorLocationString = locationString;
  if (isLiveGpsActive !== undefined) data.buses[idx].isLiveGpsActive = Boolean(isLiveGpsActive);
  if (currentStop) data.buses[idx].currentStop = currentStop;
  if (nextStop) data.buses[idx].nextStop = nextStop;
  if (eta) data.buses[idx].eta = eta;

  saveState(data);
  res.status(200).json({ status: 'success', message: 'Bus location updated', data: data.buses[idx] });
});

router.delete('/buses/:regNumber', (req: Request, res: Response) => {
  const data = loadState();
  const cleanReg = req.params.regNumber.trim().toUpperCase();
  const beforeCount = data.buses.length;
  data.buses = data.buses.filter((b) => b.regNumber.toUpperCase() !== cleanReg);

  if (data.buses.length === beforeCount) {
    return res.status(404).json({ status: 'error', message: `Bus ${cleanReg} not found` });
  }

  saveState(data);
  res.status(200).json({ status: 'success', message: `Bus ${cleanReg} deleted successfully` });
});

// Admin Approval Action
router.post('/buses/:regNumber/verify', (req: Request, res: Response) => {
  const data = loadState();
  const cleanReg = req.params.regNumber.trim().toUpperCase();
  const idx = data.buses.findIndex((b) => b.regNumber.toUpperCase() === cleanReg);

  if (idx === -1) {
    return res.status(404).json({ status: 'error', message: `Bus ${cleanReg} not found` });
  }

  (data.buses[idx] as any).verificationStatus = 'ADMIN_APPROVED';
  (data.buses[idx] as any).isApprovedByAdmin = true;
  saveState(data);
  res.status(200).json({
    status: 'success',
    message: `Bus ${cleanReg} verified and authorized for public service by EnRoute Fleet Operations`,
    data: data.buses[idx],
  });
});

// Admin Rejection Action
router.post('/buses/:regNumber/reject', (req: Request, res: Response) => {
  const data = loadState();
  const cleanReg = req.params.regNumber.trim().toUpperCase();
  const idx = data.buses.findIndex((b) => b.regNumber.toUpperCase() === cleanReg);

  if (idx === -1) {
    return res.status(404).json({ status: 'error', message: `Bus ${cleanReg} not found` });
  }

  (data.buses[idx] as any).verificationStatus = 'REJECTED';
  (data.buses[idx] as any).isApprovedByAdmin = false;
  saveState(data);
  res.status(200).json({
    status: 'success',
    message: `Bus ${cleanReg} rejected by EnRoute Fleet Operations`,
    data: data.buses[idx],
  });
});

// -----------------------------------------------------------------------------
// 4. CONDUCTOR CRUD ENDPOINTS
// -----------------------------------------------------------------------------

router.post('/conductors', (req: Request, res: Response) => {
  const data = loadState();
  const { fullName, userId, phoneNumber, licenseNumber, assignedBusReg, assignedBusName } = req.body;

  if (!fullName || !userId) {
    return res.status(400).json({ status: 'error', message: 'fullName and userId are required' });
  }

  const newId = `COND-${data.conductors.length + 1}`;
  const newConductor = {
    id: newId,
    fullName: fullName.trim(),
    userId: userId.trim().toLowerCase(),
    phoneNumber: phoneNumber || `+91 98470 ${Math.floor(10000 + Math.random() * 90000)}`,
    licenseNumber: licenseNumber || `KL-COND-${Math.floor(1000 + Math.random() * 9000)}`,
    assignedBusReg: assignedBusReg || 'Unassigned',
    assignedBusName: assignedBusName || 'Unassigned',
    role: 'ROLE_CONDUCTOR',
    status: 'ACTIVE',
  };

  data.conductors.push(newConductor);
  saveState(data);
  res.status(201).json({ status: 'success', message: 'Conductor created', data: newConductor });
});

router.put('/conductors/:id', (req: Request, res: Response) => {
  const data = loadState();
  const id = req.params.id;
  const idx = data.conductors.findIndex((c) => c.id === id || c.userId === id);

  if (idx === -1) {
    return res.status(404).json({ status: 'error', message: `Conductor ${id} not found` });
  }

  const c = data.conductors[idx];
  data.conductors[idx] = {
    ...c,
    fullName: req.body.fullName !== undefined ? req.body.fullName : c.fullName,
    phoneNumber: req.body.phoneNumber !== undefined ? req.body.phoneNumber : c.phoneNumber,
    licenseNumber: req.body.licenseNumber !== undefined ? req.body.licenseNumber : c.licenseNumber,
    assignedBusReg: req.body.assignedBusReg !== undefined ? req.body.assignedBusReg : c.assignedBusReg,
    assignedBusName: req.body.assignedBusName !== undefined ? req.body.assignedBusName : c.assignedBusName,
    status: req.body.status !== undefined ? req.body.status : c.status,
  };

  saveState(data);
  res.status(200).json({ status: 'success', message: 'Conductor updated', data: data.conductors[idx] });
});

router.delete('/conductors/:id', (req: Request, res: Response) => {
  const data = loadState();
  const id = req.params.id;
  const beforeCount = data.conductors.length;
  data.conductors = data.conductors.filter((c) => c.id !== id && c.userId !== id);

  if (data.conductors.length === beforeCount) {
    return res.status(404).json({ status: 'error', message: `Conductor ${id} not found` });
  }

  saveState(data);
  res.status(200).json({ status: 'success', message: `Conductor ${id} deleted successfully` });
});

// -----------------------------------------------------------------------------
// 5. TICKETS CRUD ENDPOINTS
// -----------------------------------------------------------------------------

router.post('/tickets', (req: Request, res: Response) => {
  const data = loadState();
  const ticket = req.body;
  if (!ticket.ticketNumber && !ticket.id) {
    ticket.ticketNumber = `KL-SBK-${Date.now()}`;
  }
  ticket.id = ticket.id || ticket.ticketNumber;
  ticket.issuedAt = ticket.issuedAt || new Date().toISOString();

  data.tickets.unshift(ticket);
  saveState(data);
  res.status(201).json({ status: 'success', message: 'Ticket saved', data: ticket });
});

router.delete('/tickets/:id', (req: Request, res: Response) => {
  const data = loadState();
  const id = req.params.id;
  const beforeCount = data.tickets.length;
  data.tickets = data.tickets.filter((t) => t.id !== id && t.ticketNumber !== id);

  if (data.tickets.length === beforeCount) {
    return res.status(404).json({ status: 'error', message: `Ticket ${id} not found` });
  }

  saveState(data);
  res.status(200).json({ status: 'success', message: `Ticket ${id} deleted` });
});

// -----------------------------------------------------------------------------
// 6. VISUAL INTERACTIVE DASHBOARD SERVING
// -----------------------------------------------------------------------------

router.get('/', (req: Request, res: Response) => {
  const data = loadState();
  if (fs.existsSync(ADMIN_HTML_PATH)) {
    const raw = fs.readFileSync(ADMIN_HTML_PATH, 'utf-8');
    const injected = raw.replace('/*__STATE_DATA__*/null', JSON.stringify(data));
    res.setHeader('Content-Type', 'text/html');
    return res.status(200).send(injected);
  }
  return res.status(500).send('Admin dashboard HTML file not found at: ' + ADMIN_HTML_PATH);
});

export default router;
