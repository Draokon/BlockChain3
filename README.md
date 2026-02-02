# Decentralizuota Aukciono Platforma (DApp)

Tai išmanioji sutartis, skirta skaidrių ir saugių aukcionų įgyvendinimui Ethereum tinkle. Užtikrinama, jog visi statymai būtų viešai matomi, o lėšų grąžinimas būtų saugus ir automatizuotas.

## Poreikis
Tradicinėse sistemose aukciono organizatorius gali būti nepatikimas. Ši aplikacija išsprendžia pasitikėjimo problemą:
* **Skaidrumas:** Visi statymai ir laikas fiksuojami.
* **Saugumas:** Pinigai saugomi kontrakte, o ne pas trečiąsias šalis.
* **Sąžiningumas:** Naudojamas *Pull-over-Push* mechanizmas – pralaimėję dalyviai patys atsiima savo lėšas, todėl kontraktas negali būti užblokuotas piktybinių vartotojų.

## Darbo tikslas
* Įgyvendinti aukciono logiką naudojant **Solidity** (statymų priėmimas, laiko kontrolė, lėšų paskirstymas).
* Užtikrinti saugumą naudojant **Re-entrancy** apsaugą ir *Pull-over-Push* lėšų atsiėmimui.
* Sukurti interaktyvią naudotojo sąsają su **ethers.js** biblioteka.
* Integruoti **MetaMask** piniginę sandorių vykdymui. Sutarties veikimo patikrinimas lokaliame ir viešajame tinkle. 

---

## Verslo modelis ir logika

### Dalyviai
1. **Pardavėjas (Seller):**
   * Sukuria aukcioną nustatydamas pradinę kainą ir trukmę.
   * Gali atšaukti aktyvų aukcioną (Cancel).
   * Pasibaigus laikui, užbaigia aukcioną (`finalize`) ir gauna ETH.
2. **Pirkėjas (Bidder):**
   * Teikia statymus (Bid).
   * Jei jo statymas permušamas, jis gali atsiimti savo ETH per `withdrawRefund` (Withdraw) .
   * Laimėtojas gauna teisę į aukciono objektą.

### Verslo scenarijus
1. **Pradžia:** Pardavėjas sukuria sutartį su `minBid` (minimalia suma, pvz., 0.1 ETH) ir `duration` (aukciono laiko galiojimu, pvz., 3600s).
2. **Eiga:** Dalyviai teikia statymus. Kiekvienas naujas didesnis statymas "užrakina" lėšas sutartyje, o senas statymas perkeliamas į `pendingReturns` ir praleimėjęs dalyvis gali lėšas bet kada susigrąžinti. Taip pat realiu laiku skelbiamas laimetojas (`highestBidder`) ir rodoma statymų istorija. 
3. **Pabaiga:** Laikui pasibaigus pardavėjas užbaigia aukcioną ir pirkėjas atsiima lėšas už pardavimą.

### Sutarties funkcijos

| Funkcija | Paskirtis | Kas gali kviesti? |
| :--- | :--- | :--- |
| `bid()` | Atlieka statymą. Tikrina, ar suma didesnė už esamą. | Bet kas |
| `withdrawRefund()` | Grąžina lėšas pralaimėjusiems dalyviams. | Dalyviai / pardavėjas |
| `finalize()` | Užbaigia aukcioną ir perveda lėšas pardavėjui. | Tik pardavėjas |
| `cancel()` | Atšaukia aukcioną ir grąžina lėšas. | Tik pardavėjas |

---

## Naudotos technologijos
* **Solidity ^0.8.20** – Išmanioji sutartis.
* **Ethers.js (v5.7.2)** – Komunikacija su Blockchain.
* **MetaMask** – Piniginė ir transakcijų pasirašymas.
* **HTML/CSS/JS** – Vartotojo sąsaja.
* **Mermaid.live** - sekų diagramos kūrimas.
* **github copilot**, **chat.gpt**, **gemini** - sutarties kūrimas, funkcijų išsiaiškinimas, klaidų ieškojimas, susiejimo pagalba.

### Sekų diagrama
Vaizduojama sąveika tarp vartotojo (pirkėjas, pardavėjas), MetaMask, išmaniosios sutarties ir Ethereum tinklo:

`Vartotojas (Bid)` -> `MetaMask (Sign TX)` -> `Blockchain (Update HighestBid)` -> `UI (Update State)`

<img width="534" height="685" alt="image" src="https://github.com/user-attachments/assets/f5080b0a-0ec8-4771-b7a3-9430ff90353d" />

---

## Paleidimo instrukcija

### Reikalavimai:
* [Node.js](https://nodejs.org/) (v16+)
* [MetaMask](https://metamask.io/) plėtinys naršyklėje.
* [Ganache](https://trufflesuite.com/ganache/) (vietiniam testavimui) arba Sepolia ETH.

### Žingsniai:

1. **Klonuoti repozitoriją:**
   ```bash
   git clone [https://github.com/Draokon/BlockChain3.git)
2. **Įdiegti reikiamus įrankius ir priklausomybes:**
   ``` bash
   npm install
3. **Įdiegti gloabaliai:**
   ``` bash
   npm install -g truffle ganache
3. **Paleisti Ganache:**
   ``` bash
   npm run ganache
5. **Naujame terminalo lange kompiliuoti ir įdiegti išmaniąsias sutartis:**
   ``` bash
   truffle migrate --reset
7. **Parsisiųsti ir konfigūruoti Metamask**
8. **Paleisti nuadotojo sąsają**
