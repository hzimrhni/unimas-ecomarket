const crypto = require("crypto");
const path = require("path");

const admin = require("firebase-admin");
const {defineSecret} = require("firebase-functions/params");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const nodemailer = require("nodemailer");

admin.initializeApp();

const db = admin.firestore();
const smtpEmail = defineSecret("SMTP_EMAIL");
const smtpAppPassword = defineSecret("SMTP_APP_PASSWORD");

const OTP_EXPIRY_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_REQUESTS_PER_HOUR = 5;
const MAX_VERIFY_ATTEMPTS = 5;
const logoAssetPath = path.join(__dirname, "..", "assets", "ecomarket_wordlogo.png");

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function ensureStudentEmail(email) {
  if (!email || !email.endsWith("@siswa.unimas.my")) {
    throw new HttpsError(
        "invalid-argument",
        "Please use your UNIMAS student email.",
    );
  }
}

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function generateOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

function formatRecipientName(email) {
  const localPart = normalizeEmail(email).split("@")[0].trim();
  if (!localPart) {
    return "there";
  }

  return localPart
      .replace(/[._-]+/g, " ")
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
      .join(" ");
}

function buildOtpHash({sessionId, email, otp}) {
  return sha256(`${sessionId}:${normalizeEmail(email)}:${otp}`);
}

function createTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: smtpEmail.value(),
      pass: smtpAppPassword.value(),
    },
  });
}

function buildOtpEmailHtml({recipientName, otp, formattedDate}) {
  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="ie=edge" />
    <meta name="color-scheme" content="light dark" />
    <meta name="supported-color-schemes" content="light dark" />
    <title>UNIMAS EcoMarket OTP</title>
    <link
      href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap"
      rel="stylesheet"
    />
    <style>
      :root {
        color-scheme: light dark;
        supported-color-schemes: light dark;
      }

      .email-preheader {
        display: none;
        max-height: 0;
        overflow: hidden;
        opacity: 0;
        mso-hide: all;
        visibility: hidden;
      }

      @media screen and (max-width: 700px) {
        .email-outer {
          width: 100% !important;
        }

        .email-header {
          margin-bottom: 12px !important;
        }

        .email-frame {
          padding: 28px 16px 36px !important;
          background-size: 620px 360px !important;
        }

        .email-header-table,
        .email-header-table tbody,
        .email-header-table tr,
        .email-header-logo-cell,
        .email-header-date-cell {
          display: block !important;
          width: 100% !important;
          text-align: center !important;
        }

        .email-header-date-cell {
          padding-top: 12px !important;
          padding-bottom: 8px !important;
        }

        .email-logo {
          display: block !important;
          height: 30px !important;
          margin: 0 auto !important;
        }

        .email-card {
          margin-top: 36px !important;
          padding: 52px 20px 60px !important;
          border-radius: 22px !important;
        }

        .email-title {
          font-size: 22px !important;
        }

        .email-greeting,
        .email-copy,
        .email-help,
        .email-footer-title,
        .email-footer-copy {
          font-size: 15px !important;
          line-height: 1.7 !important;
        }

        .otp-code {
          margin-top: 36px !important;
          font-size: 30px !important;
          letter-spacing: 12px !important;
        }

        .email-help {
          max-width: 100% !important;
          margin-top: 48px !important;
          padding: 0 8px !important;
        }

        .email-divider {
          margin-top: 16px !important;
        }
      }

      @media (prefers-color-scheme: dark) {
        body,
        .email-shell {
          background: #0f172a !important;
        }

        .email-frame {
          background: #111827 !important;
          color: #e5e7eb !important;
        }

        .email-card {
          background: #1f2937 !important;
        }

        .email-title,
        .email-greeting,
        .email-copy,
        .email-footer-title,
        .email-footer-copy {
          color: #f9fafb !important;
        }

        .email-help {
          color: #cbd5e1 !important;
        }

        .email-link {
          color: #7dd3fc !important;
        }

        .email-divider {
          border-top-color: #334155 !important;
        }

        .otp-code {
          color: #fda4af !important;
        }
      }
    </style>
  </head>
  <body
    class="email-shell"
    style="
      margin: 0;
      font-family: 'Poppins', sans-serif;
      background: #ffffff;
      font-size: 14px;
    "
  >
    <div class="email-preheader">
      Your UNIMAS EcoMarket OTP is ready. This verification code expires in 5 minutes.
    </div>
    <div
      class="email-outer email-frame"
      style="
        max-width: 680px;
        margin: 0 auto;
        padding: 45px 30px 60px;
        background: #f4f7ff;
        background-image: url(https://archisketch-resources.s3.ap-northeast-2.amazonaws.com/vrstyler/1661497957196_595865/email-template-background-banner);
        background-repeat: no-repeat;
        background-size: 800px 452px;
        background-position: top center;
        font-size: 14px;
        color: #434343;
      "
    >
      <header class="email-header">
        <table class="email-header-table" style="width: 100%;">
          <tbody>
            <tr>
              <td class="email-header-logo-cell">
                <img
                  class="email-logo"
                  src="cid:ecomarket-wordlogo@unimas-ecomarket"
                  alt="UNIMAS EcoMarket"
                  height="36"
                  style="
                    display: block;
                    height: 36px;
                    width: auto;
                  "
                />
              </td>
              <td class="email-header-date-cell" style="text-align: right;">
                <span
                  style="font-size: 16px; line-height: 30px; color: #ffffff;"
                  >${formattedDate}</span
                >
              </td>
            </tr>
          </tbody>
        </table>
      </header>

      <main>
        <div
          class="email-card"
          style="
            margin: 0;
            margin-top: 70px;
            padding: 92px 30px 115px;
            background: #ffffff;
            border-radius: 30px;
            text-align: center;
          "
        >
          <div style="width: 100%; max-width: 489px; margin: 0 auto;">
            <h1
              class="email-title"
              style="
                margin: 0;
                font-size: 24px;
                font-weight: 500;
                color: #1f1f1f;
              "
            >
              Your OTP
            </h1>
            <p
              class="email-greeting"
              style="
                margin: 0;
                margin-top: 17px;
                font-size: 16px;
                font-weight: 500;
                line-height: 1.6;
              "
            >
              Hey ${recipientName},
            </p>
            <p
              class="email-copy"
              style="
                margin: 0;
                margin-top: 17px;
                font-weight: 500;
                letter-spacing: 0.56px;
                line-height: 1.8;
              "
            >
              Thank you for choosing UNIMAS EcoMarket. Use the following OTP
              to complete your sign-in procedure. This code is valid for
              <span style="font-weight: 600; color: #1f1f1f;">5 minutes</span>.
              Do not share it with anyone, including our staff.
            </p>
            <p
              class="otp-code"
              style="
                margin: 0;
                margin-top: 60px;
                font-size: 40px;
                font-weight: 600;
                letter-spacing: 25px;
                color: #ba3d4f;
              "
            >
              ${otp}
            </p>
          </div>
        </div>

        <p
          class="email-help"
          style="
            max-width: 400px;
            margin: 0 auto;
            margin-top: 90px;
            text-align: center;
            font-weight: 500;
            color: #8c8c8c;
            line-height: 1.8;
          "
        >
          Need help? Ask at
          <a
            class="email-link"
            href="mailto:unimas.ecomarket@gmail.com"
            style="color: #499fb6; text-decoration: none;"
            >unimas.ecomarket@gmail.com</a
          >
          or contact the UNIMAS EcoMarket support team.
        </p>
      </main>

      <footer
        class="email-divider"
        style="
          width: 100%;
          max-width: 490px;
          margin: 20px auto 0;
          text-align: center;
          border-top: 1px solid #e6ebf1;
        "
      >
        <p
          class="email-footer-title"
          style="
            margin: 0;
            margin-top: 40px;
            font-size: 16px;
            font-weight: 600;
            color: #434343;
            line-height: 1.6;
          "
        >
          UNIMAS EcoMarket
        </p>
        <p
          class="email-footer-copy"
          style="margin: 0; margin-top: 8px; color: #434343; line-height: 1.6;"
        >
          Universiti Malaysia Sarawak
        </p>
        <p
          class="email-footer-copy"
          style="margin: 0; margin-top: 16px; color: #434343; line-height: 1.6;"
        >
          Copyright &copy; 2026 UNIMAS EcoMarket. All rights reserved.
        </p>
      </footer>
    </div>
  </body>
</html>`;
}


async function sendOtpEmail({email, otp}) {
  const recipientName = formatRecipientName(email);
  const formattedDate = new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date());

  await createTransporter().sendMail({
    from: smtpEmail.value(),
    to: email,
    subject: "UNIMAS EcoMarket OTP Verification",
    text: `Hello ${recipientName},\n\nYour OTP code is ${otp}. It will expire in 5 minutes.\n\nNeed help? Contact unimas.ecomarket@gmail.com.\n\nUNIMAS EcoMarket`,
    html: buildOtpEmailHtml({recipientName, otp, formattedDate}),
    attachments: [{
      filename: "ecomarket_wordlogo.png",
      path: logoAssetPath,
      cid: "ecomarket-wordlogo@unimas-ecomarket",
    }],
  });
}

async function enforceOtpRateLimit({emailKey, ipAddress}) {
  const rateRef = db.collection("otpRateLimits").doc(emailKey);
  const now = admin.firestore.Timestamp.now();
  const nowMs = now.toMillis();

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(rateRef);
    const data = snapshot.exists ? snapshot.data() : null;
    const lastRequestedAt = data?.lastRequestedAt;
    const windowStartedAt = data?.windowStartedAt;
    const requestCount = data?.requestCount || 0;

    if (lastRequestedAt &&
        nowMs - lastRequestedAt.toMillis() < RESEND_COOLDOWN_MS) {
      throw new HttpsError(
          "resource-exhausted",
          "Please wait a minute before requesting another OTP.",
      );
    }

    const isSameWindow = windowStartedAt &&
        nowMs - windowStartedAt.toMillis() < 60 * 60 * 1000;
    const nextCount = isSameWindow ? requestCount + 1 : 1;

    if (nextCount > MAX_REQUESTS_PER_HOUR) {
      throw new HttpsError(
          "resource-exhausted",
          "Too many OTP requests. Please try again later.",
      );
    }

    transaction.set(rateRef, {
      requestCount: nextCount,
      windowStartedAt: isSameWindow ? windowStartedAt : now,
      lastRequestedAt: now,
      lastIpAddress: ipAddress,
    }, {merge: true});
  });
}

async function getOrCreateUserByEmail(email) {
  try {
    return await admin.auth().getUserByEmail(email);
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }

    return admin.auth().createUser({
      email,
      emailVerified: true,
    });
  }
}

exports.requestOtp = onCall(
    {secrets: [smtpEmail, smtpAppPassword]},
    async (request) => {
      const email = normalizeEmail(request.data?.email);
      ensureStudentEmail(email);

      const emailKey = sha256(email);
      const ipAddress = request.rawRequest.ip || "unknown";
      await enforceOtpRateLimit({emailKey, ipAddress});

      const otp = generateOtp();
      const sessionId = crypto.randomBytes(16).toString("hex");
      const now = admin.firestore.Timestamp.now();
      const expiresAt = admin.firestore.Timestamp.fromMillis(
          now.toMillis() + OTP_EXPIRY_MS,
      );

      await db.collection("otpSessions").doc(sessionId).set({
        email,
        emailKey,
        otpHash: buildOtpHash({sessionId, email, otp}),
        createdAt: now,
        expiresAt,
        attemptCount: 0,
        used: false,
      });

      try {
        await sendOtpEmail({email, otp});
      } catch (error) {
        await db.collection("otpSessions").doc(sessionId).delete();
        throw new HttpsError(
            "internal",
            "Unable to send OTP email right now. Please try again later.",
        );
      }

      return {
        sessionId,
        expiresInSeconds: OTP_EXPIRY_MS / 1000,
      };
    },
);

exports.verifyOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const sessionId = String(request.data?.sessionId || "").trim();
  const otp = String(request.data?.otp || "").trim();

  ensureStudentEmail(email);

  if (!sessionId || !/^[a-f0-9]{32}$/i.test(sessionId)) {
    throw new HttpsError("invalid-argument", "Invalid OTP session.");
  }

  if (!/^\d{6}$/.test(otp)) {
    throw new HttpsError("invalid-argument", "OTP must be 6 digits.");
  }

  const sessionRef = db.collection("otpSessions").doc(sessionId);
  const sessionSnapshot = await sessionRef.get();

  if (!sessionSnapshot.exists) {
    throw new HttpsError(
        "not-found",
        "This OTP session was not found. Please request a new OTP.",
    );
  }

  const session = sessionSnapshot.data();
  const nowMs = Date.now();

  if (session.email !== email) {
    throw new HttpsError(
        "permission-denied",
        "This OTP does not belong to the provided email.",
    );
  }

  if (session.used) {
    throw new HttpsError(
        "failed-precondition",
        "This OTP has already been used. Please request a new OTP.",
    );
  }

  if (session.expiresAt.toMillis() < nowMs) {
    await sessionRef.delete();
    throw new HttpsError(
        "deadline-exceeded",
        "This OTP has expired. Please request a new OTP.",
    );
  }

  if ((session.attemptCount || 0) >= MAX_VERIFY_ATTEMPTS) {
    await sessionRef.delete();
    throw new HttpsError(
        "resource-exhausted",
        "Too many incorrect attempts. Please request a new OTP.",
    );
  }

  const otpHash = buildOtpHash({sessionId, email, otp});
  if (otpHash !== session.otpHash) {
    await sessionRef.update({
      attemptCount: admin.firestore.FieldValue.increment(1),
      lastFailedAt: admin.firestore.Timestamp.now(),
    });

    throw new HttpsError("permission-denied", "Invalid OTP.");
  }

  await sessionRef.update({
    used: true,
    verifiedAt: admin.firestore.Timestamp.now(),
  });

  const userRecord = await getOrCreateUserByEmail(email);
  const customToken = await admin.auth().createCustomToken(userRecord.uid);

  return {
    customToken,
    uid: userRecord.uid,
  };
});
