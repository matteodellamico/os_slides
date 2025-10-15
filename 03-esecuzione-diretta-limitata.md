---
marp: true
style: |
  pre {
    font-size: 0.68em;
  }
  section { 
    background: #f5f5f5ff;
  }
  section.design {
    background: #e9d992ff;
  }
  section.aside {
    background: #d0f0c0ff;
  }
  div.small tr {
    font-size: 0.83em;
  }
  div.smaller tr {
    font-size: 0.7em;
  }
---

# Esecuzione diretta limitata

Matteo Dell'Amico

<a href="https://creativecommons.org/licenses/by-sa/4.0/"><img src="https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-sa.png" alt="CC-BY-SA" width="100" /></a> [CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

Sorgenti [Marp](https://marp.app/) su https://github.com/matteodellamico/os_slides

Fonte: [*Mechanism: Limited Direct Execution*](https://pages.cs.wisc.edu/~remzi/OSTEP/cpu-mechanisms.pdf), capitolo 6 di [*Operating Systems: Three Easy Pieces*](http://pages.cs.wisc.edu/~remzi/OSTEP/), di Remzi H. Arpaci-Dusseau e Andrea C. Arpaci-Dusseau.

---

# Come gestire il time sharing?

![bg left:30% 100%](https://openclipart.org/image/2400px/svg_to_png/2998/rihard-Clock-Calendar-1.png)

Il time sharing ci permette di **virtualizzare la CPU**
- Ogni processo ha l'illusione di avere una CPU tutta per sé

Ma **come implementare il time sharing** in maniera **sicura** ed **efficiente**?

---

# Esecuzione diretta (non limitata)

<div class="small">

| OS                                       |Programma                  |
|------------------------------------------|---------------------------|
| Crea il nodo nella lista dei processi    |                           |
| Alloca e carica in memoria               |                           |
| Mette `argc` e `argv` sullo stack        |                           |
| Azzera i registri                        |                           |
| Chiama `main`                            |                           |
|                                          | Esegue `main`             |
|                                          | Chiama `return` da `main` |
| Libera la memoria                        |                           |
| Rimuove il nodo dalla lista dei processi |                           |

</div>

---

# Problema 1: sicurezza

Ci sono azioni **pericolose** ma **necessarie** per un programma, ad es.:
- input/output su disco
- allocazione di memoria

Se i programmi potessero leggere o scrivere ovunque sul disco o accedere ovunque alla memoria, potrebbero facilmente **compromettere il sistema**
- bug
- malware

**Come possiamo **limitare** i programmi, senza perdere efficienza?**

---

# L'hardware ci aiuta

<!-- root è un utente, i suoi programmi vengono eseguiti in user mode -->

L'hardware del processore fornisce due **modalità** di esecuzione:
- modalità **utente** (*user mode*)
  - esegue i processi
  - **non può** eseguire istruzioni riservate
- modalità **kernel** (*kernel mode*)
  - per eseguire il sistema operativo
  - può eseguire **qualsiasi** istruzione della CPU

---

# Chiamate di sistema (*system calls* o *syscalls*)

<!-- anche qui ci aiuta l'hardware -->

Se solo il SO può eseguire certe istruzioni, come può un programma, ad esempio, **scrivere su disco** o **allocare memoria**?

* Questo avviene tramite le **chiamate di sistema**
* Si usa un'istruzione speciale della CPU (***trap***) che passa il controllo al kernel
  * Un'istruzione analoga (***return from trap***) riporta il controllo al programma
* La scelta della syscall viene fatta impostando un numero in un registro
* Eventuali parametri vanno messi in altri registri o nello stack
* Un OS moderno ha centinaia di syscall (vedi [queste](https://www.chromium.org/chromium-os/developer-library/reference/linux-constants/syscalls/) [tabelle](https://filippo.io/linux-syscall-table/) per Linux)

---

<!-- _class: aside -->

# ...ma `open` è una syscall o una funzione?

* La `open` (come tutte le parenti) che chiamiamo in C è una **funzione di libreria**
* La syscall `open` esiste, ma di solito non la chiamiamo direttamente
* La funzione di libreria, in assembly, mette i parametri nei registri giusti e chiama la trap
  * I valori che erano nei registri vengono salvati nello stack e ripristinati dopo la syscall
* Il programmatore può evitare l'assembly e scrivere codice portabile

---

<!-- _class: design -->

![XKCD: Exploits of a Mum](https://imgs.xkcd.com/comics/exploits_of_a_mom.png) (https://xkcd.com/327/)


# Design tip: attenzione agli input degli utenti

Un numero enorme di vulnerabilità di sicurezza nasce da **input non validi**

Esempio: bisogna verificare che `write` non scriva nella memoria del kernel

Quando arriva un input da un utente, bisogna trattarlo con **estrema cautela**

In generale, meglio **terminare** programmi che fanno qualcosa di illegale

---

# Tabella delle trap

- All'avvio, il SO imposta una **tabella delle trap**
  - un array di puntatori a funzione (una per ogni syscall)
- Perché non permettere all'utente di decidere a che indirizzo saltare nel kernel?
  * Sicurezza: l'utente potrebbe saltare a qualsiasi punto
  * La tecnica del [return oriented programming](https://en.wikipedia.org/wiki/Return-oriented_programming) permette di eseguire codice arbitrario 

---

# Kernel stack

Ogni processo ha un suo *kernel stack*
- diverso dallo *user stack* usato dal programma

Serve per **salvare i registri** quando si entra in kernel mode

---

# Esecuzione diretta limitata: avvio

<!-- avendo impostato PC, il salto a `main` è automatico -->

<div class="small">

| OS                                              | HW                                     | Programma     |
|-------------------------------------------------|----------------------------------------|---------------|
| Crea il nodo nella lista dei processi           |                                        |               |
| Alloca e carica in memoria                      |                                        |               |
| Mette `argv` sullo user stack                   |                                        |               |
| Registri (inclusi PC e `argc`) nel kernel stack |                                        |               |
| Chiama `return-from-trap`                       |                                        |               |
|                                                 | Imposta i registri con il kernel stack |               |
|                                                 | Passa a user mode                      |               |
|                                                 |                                        | Esegue `main` |

</div>

---

# Esecuzione diretta limitata: system call

<!-- anche la terminazione chiama una trap -->

<div class="smaller">

| OS                                              | HW                                     | Programma             |
|-------------------------------------------------|----------------------------------------|-----------------------|
|                                                 |                                        | Imposta i registri    |
|                                                 |                                        | Chiama `trap`         |
|                                                 | Salva i registri sul kernel stack      |                       |
|                                                 | Passa a kernel mode                    |                       |
|                                                 | Legge il numero della syscall          |                       |
|                                                 | Chiama la funzione della tabella       |                       |
| Esegue la syscall                               |                                        |                       |
| Chiama `return-from-trap`                       |                                        |                       |
|                                                 | Ripristina i registri dal kernel stack |                       |
|                                                 | Passa a user mode                      |                       |
|                                                 |                                        | Riprende l'esecuzione |


</div>

---

<!-- idee? -->

# Problema 2: passare da un processo all'altro

Sembra facile: si salvano i registri di un processo, si caricano quelli di un altro e si riprende l'esecuzione.

Ma come fa il SO a **interrompere** un processo che sta eseguendo in user mode? **Se la CPU ce l'ha il processo, non ce l'ha l'OS!**

---

# Multitasking cooperativo

![bg right:40%](https://upload.wikimedia.org/wikipedia/en/8/8a/MacOS81_screenshot.png)
![bg](https://upload.wikimedia.org/wikipedia/en/7/73/Windows_3.11_workspace.png)

Vecchi OS
- ad es. MacOS Classic, Windows $\leq$ 3.11

Il processo in esecuzione **cede volontariamente** la CPU al SO
- quando chiama una syscall
- syscall per "dare la precedenza": `yield`

 Se un processo non cede la CPU, gli altri non possono eseguire
 - Unica soluzione: reboot!

---

<!-- _class: design -->

![bg left:35% width:500px](https://raw.githubusercontent.com/matteodellamico/os_slides/2a1e5aee02e30afa975f11034a0c763cdc38d0b4/images/itcrowd.png)

# Design tip: Ctrl-Alt-Del

Noi informatici veniamo presi in giro perché proponiamo il reboot come soluzione

Non è elegante, ma talvolta **funziona** perché riporta un sistema complesso a uno stato conosciuto

Esempio: memory leak (memoria allocata e non liberata)

Alcuni sistemi eseguono reboot periodici

---

# Multitasking "vero" (preemptive)

C'è di nuovo bisogno di un **meccanismo hardware**

**Timer interrupt**: un dispositivo hardware genera un'**interrupt** periodico
- frequenza impostata dal sistema (es.: 10 ms)
- gli OS moderni sono ***tickless***: il timer viene impostato ogni volta che serve

Gli interrupt sono simili alle trap, ma sono **asincroni** (non dipendono dal programma in esecuzione)
- Vengono generati da **dispositivi hardware** (es.: tastiera, disco, timer...)

Un **interrupt handler** (simile a una syscall) nel kernel gestisce l'interrupt

---

<!-- _class: aside -->

# ...e se arriva un interrupt durante un interrupt?

I sistemi operativi devono gestire con molta attenzione la **concorrenza**

È un argomento che vedrete in dettaglio in corsi successivi

Sappiate che:
- gli interrupt possono essere **disabilitati** temporaneamente
- il SO può creare dei ***lock*** per proteggere certe sezioni di codice
- evitare casi senza uscita (***deadlock***) è difficile

---

# Meccanismo: context switch

<div class="smaller">

| OS                                                   | HW                                          | Programmi |
|------------------------------------------------------|---------------------------------------------|-----------|
|                                                      |                                             | Esegue A  |
|                                                      | Interrupt (timer)                           |           |
|                                                      | Salva i registri sul kernel stack di A      |           |
|                                                      | Passa a kernel mode                         |           |
| Chiama lo ***scheduler***, che sceglie di eseguire B |                                             |           |
| Attiva il kernel stack di B                          |                                             |           |
| `return-from-trap`                                   |                                             |           |
|                                                      | Ripristina i registri dal kernel stack di B |           |
|                                                      | Passa a user mode                           |           |
|                                                      |                                             | Esegue B  |
</div>

---

# Riassunto

![bg right:50%](https://images.ctfassets.net/6m9bd13t776q/5Hc8nq9ts11KFvtB2QBfpL/1ed83b04a0a18311c1264441ce8f2756/Baby_Proofing_Hero_illustrissima.webp?q=90)

L'esecuzione diretta limitata assomiglia al rendere una stanza **a prova di bambino**: copriamo le prese, blocchiamo i cassetti con contenuti pericolosi.

Analogamente
- lo **user mode** per evita che i programmi facciano danni
- il **timer interrupt** permette al SO di riprendere il controllo