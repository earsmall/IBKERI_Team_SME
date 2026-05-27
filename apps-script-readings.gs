const SHEET_NAME = 'readings';
const HEADERS = [
  'savedAt',
  'isoDate',
  'dateLabel',
  'agency',
  'title',
  'details',
  'link',
  'submitter',
  'pinHash'
];

function doGet(e) {
  const params = e.parameter || {};
  const callback = sanitizeCallback(params.callback || '');

  if (params.action === 'delete') {
    const result = withLock_(() => deleteItem_(params.savedAt || '', params.pin || ''));
    return createResponse_(result, callback);
  }

  if (params.action === 'update') {
    const result = withLock_(() => updateItem_(params));
    return createResponse_(result, callback);
  }

  const items = readItems_();
  return createResponse_({ items }, callback);
}

function doPost(e) {
  return withLock_(() => {
    const sheet = getSheet_();
    const params = e.parameter || {};

    if (params.action === 'delete') {
      const result = deleteItem_(params.savedAt || '', params.pin || '');
      return ContentService
        .createTextOutput(JSON.stringify(result))
        .setMimeType(ContentService.MimeType.JSON);
    }

    if (params.action === 'update') {
      const result = updateItem_(params);
      return ContentService
        .createTextOutput(JSON.stringify(result))
        .setMimeType(ContentService.MimeType.JSON);
    }

    if (!params.pin) {
      throw new Error('pin is required.');
    }

    params.pinHash = hashPin_(params.pin);
    appendItem_(sheet, params);

    return ContentService
      .createTextOutput(JSON.stringify({ ok: true }))
      .setMimeType(ContentService.MimeType.JSON);
  });
}

function appendItem_(sheet, params) {
  const row = HEADERS.map(key => String(params[key] || ''));
  const nextRow = sheet.getLastRow() + 1;
  const range = sheet.getRange(nextRow, 1, 1, HEADERS.length);
  range.setNumberFormat('@');
  range.setValues([row]);
}

function deleteItem_(savedAt, pin) {
  if (!savedAt) {
    return { ok: false, error: '삭제할 항목을 찾을 수 없습니다.' };
  }

  const sheet = getSheet_();
  const values = sheet.getDataRange().getValues();
  const savedAtColumn = HEADERS.indexOf('savedAt');
  const pinHashColumn = HEADERS.indexOf('pinHash');

  for (let rowIndex = values.length - 1; rowIndex >= 1; rowIndex -= 1) {
    if (String(values[rowIndex][savedAtColumn] || '') === savedAt) {
      const storedHash = String(values[rowIndex][pinHashColumn] || '');
      if (isPinHash_(storedHash) && storedHash !== hashPin_(pin)) {
        return { ok: false, error: '삭제 PIN이 맞지 않습니다.' };
      }

      sheet.deleteRow(rowIndex + 1);
      return { ok: true };
    }
  }

  return { ok: false, error: '이미 삭제되었거나 항목을 찾을 수 없습니다.' };
}

function updateItem_(params) {
  const savedAt = String(params.savedAt || '');
  const pin = String(params.pin || '');
  if (!savedAt) {
    return { ok: false, error: '수정할 항목을 찾을 수 없습니다.' };
  }

  const sheet = getSheet_();
  const values = sheet.getDataRange().getValues();
  const savedAtColumn = HEADERS.indexOf('savedAt');
  const pinHashColumn = HEADERS.indexOf('pinHash');
  const editableKeys = ['isoDate', 'dateLabel', 'agency', 'title', 'details', 'link', 'submitter'];

  for (let rowIndex = values.length - 1; rowIndex >= 1; rowIndex -= 1) {
    if (String(values[rowIndex][savedAtColumn] || '') === savedAt) {
      const storedHash = String(values[rowIndex][pinHashColumn] || '');
      if (isPinHash_(storedHash) && storedHash !== hashPin_(pin)) {
        return { ok: false, error: '수정 PIN이 맞지 않습니다.' };
      }

      editableKeys.forEach(key => {
        const columnIndex = HEADERS.indexOf(key);
        if (columnIndex >= 0) {
          sheet.getRange(rowIndex + 1, columnIndex + 1).setNumberFormat('@');
          sheet.getRange(rowIndex + 1, columnIndex + 1).setValue(String(params[key] || ''));
        }
      });
      return { ok: true };
    }
  }

  return { ok: false, error: '이미 삭제되었거나 항목을 찾을 수 없습니다.' };
}

function readItems_() {
  const sheet = getSheet_();
  const values = sheet.getDataRange().getValues();
  const displayValues = sheet.getDataRange().getDisplayValues();
  if (values.length <= 1) return [];

  const headers = values[0].map(String);
  return values
    .slice(1)
    .filter(row => row.some(cell => String(cell || '').trim()))
    .map((row, rowIndex) => {
      const item = {};
      headers.forEach((header, index) => {
        if (header === 'pinHash') {
          item.hasPin = isPinHash_(String(row[index] || ''));
          return;
        }
        item[header] = displayValues[rowIndex + 1][index] == null ? '' : String(displayValues[rowIndex + 1][index]);
      });
      return item;
    })
    .reverse();
}

function getSheet_() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = spreadsheet.getSheetByName(SHEET_NAME) || spreadsheet.insertSheet(SHEET_NAME);

  const firstRow = sheet.getRange(1, 1, 1, HEADERS.length).getValues()[0];
  const needsHeaders = HEADERS.some((header, index) => firstRow[index] !== header);

  if (needsHeaders) {
    sheet.getRange(1, 1, 1, HEADERS.length).setValues([HEADERS]);
    sheet.setFrozenRows(1);
  }

  return sheet;
}

function sanitizeCallback(value) {
  return /^[A-Za-z_$][0-9A-Za-z_$]*$/.test(value) ? value : '';
}

function hashPin_(pin) {
  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, String(pin));
  return bytes.map(byte => {
    const value = byte < 0 ? byte + 256 : byte;
    return value.toString(16).padStart(2, '0');
  }).join('');
}

function isPinHash_(value) {
  return /^[a-f0-9]{64}$/i.test(String(value || ''));
}

function withLock_(callback) {
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);

  try {
    return callback();
  } finally {
    lock.releaseLock();
  }
}

function createResponse_(payload, callback) {
  const json = JSON.stringify(payload);

  if (callback) {
    return ContentService
      .createTextOutput(`${callback}(${json});`)
      .setMimeType(ContentService.MimeType.JAVASCRIPT);
  }

  return ContentService
    .createTextOutput(json)
    .setMimeType(ContentService.MimeType.JSON);
}
