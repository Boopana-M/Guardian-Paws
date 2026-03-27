/* global Parse */

const twilio = require('twilio');

function getTwilioClient() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  if (!accountSid || !authToken) {
    throw new Error('Twilio credentials missing in environment variables.');
  }
  return twilio(accountSid, authToken);
}

Parse.Cloud.define('inviteGuardian', async (request) => {
  const user = request.user;
  if (!user) {
    throw 'Not authenticated';
  }
  const { guardianName, guardianPhone, guardianEmail } = request.params;
  if (!guardianPhone) {
    throw 'guardianPhone required';
  }

  const Guardian = Parse.Object.extend('Guardian');
  const query = new Parse.Query(Guardian);
  query.equalTo('phone', guardianPhone);
  let guardian = await query.first({ useMasterKey: true });
  if (!guardian) {
    guardian = new Guardian();
    guardian.set('phone', guardianPhone);
  }
  guardian.set('name', guardianName || 'Guardian');
  if (guardianEmail) guardian.set('email', guardianEmail);

  const linked = guardian.get('linkedUsers') || [];
  if (!linked.includes(user.id)) {
    linked.push(user.id);
  }
  guardian.set('linkedUsers', linked);
  guardian.set('acceptedInvite', false);
  await guardian.save(null, { useMasterKey: true });

  const client = getTwilioClient();
  const fromNumber = process.env.TWILIO_FROM_NUMBER;
  const appLink = process.env.GUARDIAN_PAWS_PLAYSTORE_LINK ||
    'https://example.com/guardian-paws';

  const body =
    `[Guardian-Paws Alert]\n\n` +
    `You have been added as a safety guardian for ${user.get('name') || 'your friend'}.\n\n` +
    `Install the app to monitor their safety:\n${appLink}`;

  await client.messages.create({
    body,
    to: guardianPhone,
    from: fromNumber,
  });

  return { success: true };
});

Parse.Cloud.define('linkGuardianOnSignup', async (request) => {
  const user = request.user;
  if (!user) throw 'Not authenticated';

  const phone = user.get('phone');
  if (!phone) return { linked: false };

  const Guardian = Parse.Object.extend('Guardian');
  const query = new Parse.Query(Guardian);
  query.equalTo('phone', phone);
  const guardian = await query.first({ useMasterKey: true });
  if (!guardian) return { linked: false };

  guardian.set('userId', user.id);
  guardian.set('acceptedInvite', true);
  const linked = guardian.get('linkedUsers') || [];
  if (!linked.includes(user.id)) {
    linked.push(user.id);
  }
  guardian.set('linkedUsers', linked);
  await guardian.save(null, { useMasterKey: true });

  return { linked: true };
});

Parse.Cloud.define('onProtectionModeChanged', async (request) => {
  const user = request.user;
  if (!user) throw 'Not authenticated';
  const active = request.params.active === true;

  const query = new Parse.Query('Guardian');
  query.equalTo('linkedUsers', user.id);
  const guardians = await query.find({ useMasterKey: true });

  const msg = active
    ? 'Protection Mode Activated'
    : 'Protection Mode Paused';

  const pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.containedIn(
    'user',
    guardians.map((g) => {
      const u = new Parse.User();
      u.id = g.get('userId');
      return u;
    }),
  );

  await Parse.Push.send(
    {
      where: pushQuery,
      data: {
        alert: `Guardian-Paws: ${msg} for ${user.get('name')}`,
      },
    },
    { useMasterKey: true },
  );
});

Parse.Cloud.define('scheduleSafetyCheck', async (request) => {
  const user = request.user;
  if (!user) throw 'Not authenticated';

  const SafetyEvent = Parse.Object.extend('SafetyEvent');
  const ev = new SafetyEvent();
  ev.set('userId', user.id);
  ev.set('type', 'CHECK_SCHEDULED');
  await ev.save(null, { useMasterKey: true });
});

Parse.Cloud.define('onSafetyConfirmed', async (request) => {
  const user = request.user;
  if (!user) throw 'Not authenticated';
  user.set('status', 'SAFE');
  user.set('lastCheckInTime', new Date());
  await user.save(null, { useMasterKey: true });
});

Parse.Cloud.define('onSafetyFailed', async (request) => {
  const user = request.user;
  if (!user) throw 'Not authenticated';
  user.set('status', 'RISK');
  await user.save(null, { useMasterKey: true });

  const Guardians = Parse.Object.extend('Guardian');
  const query = new Parse.Query(Guardians);
  query.equalTo('linkedUsers', user.id);
  const guardians = await query.find({ useMasterKey: true });

  const loc = user.get('lastKnownLocation');
  const battery = user.get('batteryLevel');
  const imei = user.get('imei');

  const pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.containedIn(
    'user',
    guardians.map((g) => {
      const u = new Parse.User();
      u.id = g.get('userId');
      return u;
    }),
  );

  const locationSummary = loc
    ? `Lat: ${loc.latitude.toFixed(4)}, Lng: ${loc.longitude.toFixed(4)}`
    : 'Unknown';

  const body =
    `Guardian-Paws ALERT\n\n` +
    `${user.get('name') || 'User'} did not confirm safety.\n\n` +
    `Last Location: ${locationSummary}\n` +
    `Battery: ${battery != null ? battery + '%' : 'Unknown'}\n` +
    `IMEI: ${imei || 'Unknown'}\n` +
    `Status: Potential risk detected`;

  await Parse.Push.send(
    {
      where: pushQuery,
      data: {
        alert: body,
      },
    },
    { useMasterKey: true },
  );

  const client = getTwilioClient();
  const fromNumber = process.env.TWILIO_FROM_NUMBER;

  await Promise.all(
    guardians.map((g) => {
      const phone = g.get('phone');
      if (!phone) return null;
      return client.messages.create({
        body,
        to: phone,
        from: fromNumber,
      });
    }),
  );
});

Parse.Cloud.job('monitorOfflineDevices', async (request) => {
  const User = Parse.User;
  const query = new Parse.Query(User);
  query.equalTo('protectionModeActive', true);
  const users = await query.find({ useMasterKey: true });

  const now = new Date();

  for (const user of users) {
    const updatedAt = user.updatedAt || now;
    const diffMinutes = (now.getTime() - updatedAt.getTime()) / 60000;
    if (diffMinutes > 5) {
      user.set('deviceOnline', false);
      await user.save(null, { useMasterKey: true });

      const Guardians = Parse.Object.extend('Guardian');
      const gQuery = new Parse.Query(Guardians);
      gQuery.equalTo('linkedUsers', user.id);
      const guardians = await gQuery.find({ useMasterKey: true });

      const loc = user.get('lastKnownLocation');
      const battery = user.get('batteryLevel');
      const imei = user.get('imei');

      const locationSummary = loc
        ? `Lat: ${loc.latitude.toFixed(4)}, Lng: ${loc.longitude.toFixed(4)}`
        : 'Unknown';

      const alertBody =
        `Guardian-Paws ALERT\n\n` +
        `Device for ${user.get('name') || 'User'} went offline.\n\n` +
        `Last Known Location: ${locationSummary}\n` +
        `Battery: ${battery != null ? battery + '%' : 'Unknown'}\n` +
        `IMEI: ${imei || 'Unknown'}`;

      const pushQuery = new Parse.Query(Parse.Installation);
      pushQuery.containedIn(
        'user',
        guardians.map((g) => {
          const u = new Parse.User();
          u.id = g.get('userId');
          return u;
        }),
      );

      await Parse.Push.send(
        {
          where: pushQuery,
          data: { alert: alertBody },
        },
        { useMasterKey: true },
      );

      const client = getTwilioClient();
      const fromNumber = process.env.TWILIO_FROM_NUMBER;

      await Promise.all(
        guardians.map((g) => {
          const phone = g.get('phone');
          if (!phone) return null;
          return client.messages.create({
            body: alertBody,
            to: phone,
            from: fromNumber,
          });
        }),
      );
    }
  }
});

