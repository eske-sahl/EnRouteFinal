import prisma from '../src/config/prisma';
import { hashPassword } from '../src/utils/password';
import { Role, AccountStatus } from '@prisma/client';

async function main() {
  console.log('🌱 Seeding SmartBus Kerala database with test Kerala transport data...');

  const defaultPasswordHash = await hashPassword('password123');

  // 1. Create Super Admin
  const admin = await prisma.user.upsert({
    where: { email: 'admin@enroute.transit' },
    update: {},
    create: {
      email: 'admin@enroute.transit',
      passwordHash: defaultPasswordHash,
      fullName: 'Kerala Transport Admin',
      phoneNumber: '9847000001',
      role: Role.ROLE_ADMIN,
      status: AccountStatus.ACTIVE,
    },
  });
  console.log(`✅ Admin user seeded: ${admin.email}`);

  // 2. Create Bus Owner & Profile
  const ownerUser = await prisma.user.upsert({
    where: { email: 'owner@stgeorge.com' },
    update: {},
    create: {
      email: 'owner@stgeorge.com',
      passwordHash: defaultPasswordHash,
      fullName: 'George Varghese',
      phoneNumber: '9847000002',
      role: Role.ROLE_OWNER,
      status: AccountStatus.ACTIVE,
      ownerProfile: {
        create: {
          operatorName: 'St. George Motors Ernakulam',
          isVerified: true,
        },
      },
    },
    include: { ownerProfile: true },
  });
  console.log(`✅ Bus Owner seeded: ${ownerUser.email} (${ownerUser.ownerProfile?.operatorName})`);

  const ownerProfileId = ownerUser.ownerProfile!.id;

  // 3. Create Buses
  const bus1 = await prisma.bus.upsert({
    where: { regNumber: 'KL07CD4589' },
    update: {},
    create: {
      regNumber: 'KL07CD4589',
      busName: 'SpeedWings',
      busType: 'ORDINARY',
      seatingCapacity: 48,
      ownerId: ownerProfileId,
    },
  });

  const bus2 = await prisma.bus.upsert({
    where: { regNumber: 'KL07CE1204' },
    update: {},
    create: {
      regNumber: 'KL07CE1204',
      busName: 'GreenCity Express',
      busType: 'FAST_PASSENGER',
      seatingCapacity: 52,
      ownerId: ownerProfileId,
    },
  });
  console.log(`✅ Buses seeded: ${bus1.busName} (${bus1.regNumber}), ${bus2.busName} (${bus2.regNumber})`);

  // 4. Create Conductor
  const conductor = await prisma.user.upsert({
    where: { email: 'conductor@smartbus.kerala' },
    update: {},
    create: {
      email: 'conductor@smartbus.kerala',
      passwordHash: defaultPasswordHash,
      fullName: 'Suresh Kumar',
      phoneNumber: '9847000003',
      role: Role.ROLE_CONDUCTOR,
      status: AccountStatus.ACTIVE,
    },
  });
  console.log(`✅ Conductor seeded: ${conductor.email}`);

  // 5. Create Test Passenger with Demo Wallet
  const passenger = await prisma.user.upsert({
    where: { email: 'passenger@gmail.com' },
    update: {},
    create: {
      email: 'passenger@gmail.com',
      passwordHash: defaultPasswordHash,
      fullName: 'Anjali Nair',
      phoneNumber: '9847000004',
      role: Role.ROLE_PASSENGER,
      status: AccountStatus.ACTIVE,
      wallet: {
        create: {
          balance: 250.0,
        },
      },
    },
    include: { wallet: true },
  });
  console.log(`✅ Passenger seeded: ${passenger.email} (Wallet: ₹${passenger.wallet?.balance})`);

  // 6. Create Route & Ordered Stops (Aluva to Perumbavoor via Kizhakkambalam)
  const existingRoute = await prisma.route.findFirst({
    where: { routeNumber: 'R-14' },
  });

  if (!existingRoute) {
    const route = await prisma.route.create({
      data: {
        routeNumber: 'R-14',
        sourceName: 'Aluva Stand',
        destName: 'Perumbavoor Stand',
        baseFare: 10.0,
        farePerStage: 1.5,
        stops: {
          create: [
            { stopName: 'Aluva Private Bus Stand', stageIndex: 1, latitude: 10.1076, longitude: 76.3516 },
            { stopName: 'Bank Junction', stageIndex: 2, latitude: 10.1042, longitude: 76.3551 },
            { stopName: 'Pump Junction', stageIndex: 3, latitude: 10.0984, longitude: 76.3622 },
            { stopName: 'Kizhakkambalam', stageIndex: 4, latitude: 10.0526, longitude: 76.4025 },
            { stopName: 'Pattimattom', stageIndex: 5, latitude: 10.0412, longitude: 76.4421 },
            { stopName: 'Perumbavoor Municipal Stand', stageIndex: 6, latitude: 10.1132, longitude: 76.4789 },
          ],
        },
      },
    });
    console.log(`✅ Route R-14 seeded with 6 ordered stops!`);
  } else {
    console.log(`ℹ️ Route R-14 already exists.`);
  }

  console.log('🎉 Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
