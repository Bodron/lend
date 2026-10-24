import { PDFDocument, StandardFonts, rgb } from "pdf-lib";

const ascii = (value) => String(value ?? "")
  .normalize("NFD")
  .replace(/[\u0300-\u036f]/g, "")
  .replace(/[șş]/g, "s").replace(/[ȘŞ]/g, "S")
  .replace(/[țţ]/g, "t").replace(/[ȚŢ]/g, "T")
  .replace(/[^\x20-\x7E]/g, "?");

export async function buildRentalContractPdf({ product, order, renter, signatureDataUrl }) {
  const pdf = await PDFDocument.create();
  const page = pdf.addPage([595, 842]);
  const regular = await pdf.embedFont(StandardFonts.Helvetica);
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold);
  const blue = rgb(0.188, 0.341, 0.561);
  const left = 42;
  const width = 510;
  let y = 790;

  function line(text, size = 11, font = regular, color = rgb(0.12, 0.12, 0.12)) {
    page.drawText(ascii(text), { x: left, y, size, font, color });
    y -= size + 9;
  }
  function paragraph(text) {
    const words = ascii(text).split(/\s+/);
    let row = "";
    for (const word of words) {
      const next = row ? `${row} ${word}` : word;
      if (regular.widthOfTextAtSize(next, 10) > width && row) {
        line(row, 10);
        row = word;
      } else row = next;
    }
    if (row) line(row, 10);
    y -= 5;
  }

  line("PINLEND", 22, bold, blue);
  line("Contract de inchiriere bun", 18, bold);
  y -= 8;
  const date = (value) => new Date(value).toLocaleDateString("ro-RO", { timeZone: "UTC" });
  const details = [
    ["Bun inchiriat", product.title],
    ["Proprietar", product.ownerName || "Proprietar PINLEND"],
    ["Locatar", renter.fullName || renter.email || "Utilizator PINLEND"],
    ["Locatie", [product.address, product.city].filter(Boolean).join(", ")],
    ["Perioada", `${date(order.startDate)} - ${date(order.endDate)}`],
    ["Program", `${order.pickupTime} - ${order.returnTime}`],
    ["Mod", { hour: "Ora", day: "Zi", month: "Luna" }[order.rentalMode] || order.rentalMode],
    ["Subtotal / taxa / garantie", `${order.subtotal} / ${order.serviceFee} / ${order.deposit} RON`],
    ["Total autorizat", `${order.total} RON`],
  ];
  for (const [label, value] of details) line(`${label}: ${value}`, 10, regular);
  y -= 10;

  const sections = [
    ["1. Termeni generali", "Proprietarul ofera bunul spre folosinta temporara locatarului pentru perioada specificata. Acest document este un model generat de PINLEND."],
    ["2. Predare si retur", `Predarea se face la ${order.pickupTime}, iar returul la ${order.returnTime}. Bunul se returneaza in aceeasi stare, cu exceptia uzurii normale.`],
    ["3. Responsabilitate", "Locatarul raspunde pentru folosirea corecta a bunului. Deteriorarea, pierderea sau intarzierea poate duce la retinerea garantiei."],
    ["4. Plata si garantie", `Subtotal: ${order.subtotal} RON. Taxa serviciu: ${order.serviceFee} RON. Garantie: ${order.deposit} RON. Total: ${order.total} RON.`],
    ["5. Incetare", "Contractul inceteaza la finalul perioadei sau prin acordul ambelor parti, exprimat in scris prin mesageria platformei."],
  ];
  for (const [title, body] of sections) {
    line(title, 11, bold, blue);
    paragraph(body);
  }

  const signature = await pdf.embedPng(signatureDataUrl);
  const imageSize = signature.scaleToFit(210, 65);
  page.drawText("SEMNATURA LOCATAR", { x: left, y: Math.max(120, y - 10), size: 10, font: bold });
  page.drawImage(signature, { x: left, y: Math.max(45, y - 85), width: imageSize.width, height: imageSize.height });
  page.drawText(ascii(`Generat la ${new Date().toLocaleDateString("ro-RO")}`), { x: left, y: 28, size: 9, font: regular });
  return pdf.save();
}
