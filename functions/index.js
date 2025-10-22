import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

const ALLOWED = new Set(['present', 'absent', 'pre-leave']);

function statusLabel(status) {
  switch ((status || '').toLowerCase()) {
    case 'present':
      return 'Present';
    case 'absent':
      return 'Absent';
    case 'pre-leave':
      return 'Pre-Leave';
    default:
      return status || 'Unknown';
  }
}

export const onAttendanceWrite = onDocumentWritten(
  {
    document: 'attendance/{attendanceId}',
    region: 'us-central1',
    // increase timeouts if needed:
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (event) => {
    const before = event.data?.before?.data() || null;
    const after = event.data?.after?.data() || null;

    if (!after) {
      // Deleted, ignore
      return;
    }

    const prevStatus = (before?.status || '').toLowerCase();
    const currStatus = (after?.status || '').toLowerCase();

    const isCreate = !before;
    const statusChanged = prevStatus !== currStatus;

    if (!ALLOWED.has(currStatus)) {
      return;
    }

    if (!isCreate && !statusChanged) {
      // No change -> avoid duplicate messages
      return;
    }

    const parentUid = after.parentUid;
    if (!parentUid) {
      console.log('No parentUid on attendance doc, skipping');
      return;
    }

    // Optional per-student toggle (enrollment-based). If you add this field, uncomment this block.
    // try {
    //   const enrollmentId = after.enrollmentId;
    //   if (enrollmentId) {
    //     const enrollSnap = await db.collection('enrollments').doc(enrollmentId).get();
    //     const notify = enrollSnap.exists && enrollSnap.data()?.notifyAttendance !== false; // default true
    //     if (!notify) {
    //       console.log('notifyAttendance=false, skipping for', enrollmentId);
    //       return;
    //     }
    //   }
    // } catch (e) {
    //   console.warn('notifyAttendance check failed', e);
    // }

    const tokensSnap = await db
      .collection('users')
      .doc(parentUid)
      .collection('tokens')
      .get();

    if (tokensSnap.empty) {
      console.log('No tokens for user', parentUid);
      return;
    }

    const tokens = tokensSnap.docs
      .map((d) => (d.data()?.token || d.id))
      .filter((t) => typeof t === 'string' && t.length > 0);

    if (tokens.length === 0) {
      console.log('No usable tokens for user', parentUid);
      return;
    }

    const studentName = after.studentName || 'Student';
    const course = after.course || '';
    const dateKey = after.dateKey || '';

    const title = 'Attendance';
    const friendly = currStatus === 'pre-leave' ? 'On Pre-Leave' : statusLabel(currStatus);
    const body = `${studentName}${course ? ` (${course})` : ''} is ${friendly} on ${dateKey}`;

    const message = {
      notification: { title, body },
      apns: {
        payload: { aps: { contentAvailable: true } },
        headers: { 'apns-priority': '10' },
      },
      android: {
        priority: 'high',
        notification: { channelId: 'attendance_updates' },
      },
      data: {
        type: 'attendance_update',
        status: currStatus,
        course: course,
        dateKey: dateKey,
      },
      tokens,
    };

    try {
      const resp = await messaging.sendEachForMulticast(message);
      const success = resp.successCount || 0;
      const failure = resp.failureCount || 0;
      console.log(`Sent attendance notification: success=${success}, failure=${failure}`);

      // Cleanup invalid tokens
      if (failure > 0) {
        const deletes = [];
        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            const code = r.error?.code || '';
            if (code.includes('registration-token-not-registered') || code.includes('invalid-argument')) {
              const tok = tokens[idx];
              deletes.push(
                db.collection('users').doc(parentUid).collection('tokens').doc(tok).delete().catch(() => {})
              );
            }
          }
        });
        if (deletes.length) await Promise.allSettled(deletes);
      }
    } catch (e) {
      console.error('Error sending FCM', e);
    }
  }
);
