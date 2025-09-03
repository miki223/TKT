HTMLSelectElement.prototype.hasOption = function hasOption(targetValue) {
    const children = Array.from(this.children);
    return children.some(({ value }) => value === targetValue);
}

HTMLTableRowElement.prototype.insertHeader = function insertHeader() {
  const tableHeader = document.createElement('th');
  this.appendChild(tableHeader);
  return tableHeader;
}

class File {
  constructor(data) {
    this.name = data.name;
    this.size = new FileSize(data.size);
    this.updatedAt = new Date(data.updatedAt);
    this.digest = data.digest;
    this.url = data.url;
    this.version = data.version;

    const [distro, _, scheduler, compiler] = data.name
      .replace('-diet', '')
      .split(/-|\./);

    Object.defineProperty(this, 'distro', { value: distro.toLowerCase() });
    Object.defineProperty(this, 'scheduler', { value: scheduler });
    Object.defineProperty(this, 'compiler', { value: compiler });
  }
}

class FileSize {
  constructor(bytes) {
    if (!Number.isFinite(bytes) || bytes < 0) {
      throw new Error("FileSize must be a non-negative number of bytes");
    }
    this.bytes = bytes;
  }

  valueOf() {
    return this.bytes;
  }

  toString() {
    return this.humanReadable();
  }

  humanReadable() {
    const units = ["B", "KB", "MB", "GB", "TB", "PB"];
    let size = this.bytes;
    let i = 0;

    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }

    return `${size.toFixed(2)} ${units[i]}`;
  }
}

function CopyButton(text, label = 'Copy') {
  const button = document.createElement('button');
  button.className = 'no-select';
  button.textContent = label;

  button.addEventListener('click', () => {
    navigator.clipboard
      .writeText(text)
      .then(() => {
        button.textContent = 'Copied';
        setTimeout(() => (button.textContent = label), 1500);
      })
      .catch(err => {
        console.error('Copy failed:', err);
        button.textContent = 'Failed';
        setTimeout(() => (button.textContent = label), 1500);
      });
  });

  return button;
}

function timeAgo(date) {
  if (!(date instanceof Date)) {
    throw new TypeError('Expected a Date object');
  }

  const now = new Date();
  if (date > now) return 'in the future';

  // Days
  const diffHours = Math.round((now - date) / 3_600_000);
  const diffDays = Math.round(diffHours / 24);
  if (diffDays < 1)
    return 'today';
  if (diffDays < 7)
    return diffDays === 1 ? '1 day ago' : `${diffDays} days ago`;

  // Weeks
  if (diffDays < 30) {
    const weeks = Math.round(diffDays / 7);
    return weeks === 1 ? '1 week ago' : `${weeks} weeks ago`;
  }

  // Months and years (calendar-based)
  const years = now.getFullYear() - date.getFullYear();
  const months = now.getMonth() - date.getMonth() + years * 12;

  if (months < 12)
    return months <= 1 ? '1 month ago' : `${months} months ago`;

  const fullYears = Math.round(months / 12);
  return fullYears === 1 ? '1 year ago' : `${fullYears} years ago`;
}

export async function cachedFetch(url, key, ttl = 3600) { // ttl in seconds
  const now = Date.now();
  const cached = localStorage.getItem(key);

  if (cached) {
    const { timestamp, data } = JSON.parse(cached);
    if (now - timestamp < ttl * 1000) {
      return data; // still fresh
    }
  }

  const data = await fetch(url).then((res) => res.json());

  localStorage.setItem(key, JSON.stringify({ timestamp: now, data }));
  return data;
}

export function getFiles(releases) {
  const files = [];

  const selectVersion = document.getElementById('select-version');
  const selectDistro = document.getElementById('select-distro');
  const selectScheduler = document.getElementById('select-scheduler');
  const selectCompiler = document.getElementById('select-compiler');

  let chosenVersion = 'all';
  let chosenDistro = 'all';
  let chosenScheduler = 'all';
  let chosenCompiler = 'all';

  const updateFiles = function(tableElement, fileList) {
    const newFiles = fileList
      .filter(({ version }) => {
        return version === chosenVersion || chosenVersion === 'all';
      })
      .filter(({ distro }) => {
        return distro === chosenDistro || chosenDistro === 'all';
      })
      .filter(({ scheduler }) => {
        return scheduler === chosenScheduler || chosenScheduler === 'all';
      })
      .filter(({ compiler }) => {
        return compiler === chosenCompiler || chosenCompiler === 'all';
      });

    populateTable(tableElement, newFiles);
  };

  const tableElement = document.querySelector('#releases-table');

  selectVersion.addEventListener('change', ({ target }) => {
    chosenVersion = target.value;
    updateFiles(tableElement, files);
  });

  selectDistro.addEventListener('change', ({ target }) => {
    chosenDistro = target.value;
    updateFiles(tableElement, files);
  });

  selectScheduler.addEventListener('change', ({ target }) => {
    chosenScheduler = target.value;
    updateFiles(tableElement, files);
  });

  selectCompiler.addEventListener('change', ({ target }) => {
    chosenCompiler = target.value;
    updateFiles(tableElement, files);
  });

  releases.forEach(({ name, tag_name, assets }) => {
    const option = document.createElement('option');
    option.innerText = name;
    option.value = tag_name;
    selectVersion.appendChild(option);

    assets.forEach((asset) => {
      const { name, size, updated_at, digest, browser_download_url } = asset;
      const [distro, _, scheduler, compiler] = name
        .replace('-diet', '')
        .split(/-|\./);
      const distroOption = document.createElement('option');
      const schedulerOption = document.createElement('option');
      const compilerOption = document.createElement('option');

      distroOption.text = distro;
      distroOption.value = distro.toLowerCase();
      if (!selectDistro.hasOption(distro.toLowerCase()))
        selectDistro.appendChild(distroOption);

      schedulerOption.innerText = scheduler;
      schedulerOption.value = scheduler;
      if (!selectScheduler.hasOption(scheduler))
        selectScheduler.appendChild(schedulerOption);

      compilerOption.innerText = compiler;
      compilerOption.value = compiler;
      if (!selectCompiler.hasOption(compiler))
        selectCompiler.appendChild(compilerOption);

      files.push(new File({
        name,
        size,
        updatedAt: updated_at,
        digest,
        url: browser_download_url,
        version: tag_name,
      }));
    });
  });

  return files;
}

export function populateTable(tableElement, fileList) {
  if (!tableElement.tHead) {
    tableElement.createTHead();
    const headerRow = document.createElement('tr');
    tableElement.tHead.appendChild(headerRow);

    headerRow.insertHeader().innerText = 'name';
    headerRow.insertHeader().innerText = 'size';
    headerRow.insertHeader().innerText = 'last updated';
    headerRow.insertHeader().innerText = 'sha256';
  }

  for (let i = tableElement.tBodies.length - 1; i >= 0; i--) {
    const tBody = tableElement.tBodies[i];
    for (let j = tBody.children.length - 1; j >= 0; j--) {
      const row = tBody.children[j];
      tBody.removeChild(row);
    }
    tableElement.removeChild(tBody);
  }

  const tBody = tableElement.createTBody();
  for (let i = 0, n = fileList.length; i < n; i++) {
    const { name, size, updatedAt, digest, url } = fileList[i];

    const row = tBody.insertRow();
    const nameCell = row.insertCell();
    const sizeCell = row.insertCell();
    const dateCell = row.insertCell();
    const digestCell = row.insertCell();

    const dateOptions = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
      timeZoneName: 'short'
    };

    nameCell.innerHTML = `<a href="${url}">${name}</a>`;

    sizeCell.innerText = size;
    sizeCell.style.textAlign = 'right';

    dateCell.innerText = timeAgo(updatedAt);
    dateCell.title = new Intl.DateTimeFormat('en-US', dateOptions)
      .format(updatedAt);
    dateCell.style.textAlign = 'center';

    const button = new CopyButton(digest.replace('sha256:', ''));
    button.title = digest.replace('sha256:', '');
    digestCell.appendChild(button);
    digestCell.style.textAlign = 'center';
  }
}
