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
  img[alt~="center"] {
    display: block;
    margin: 0 auto;
  }
---

# Scheduling: Multi-Level Feedback Queue

Matteo Dell'Amico

<a href="https://creativecommons.org/licenses/by-sa/4.0/"><img src="https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-sa.png" alt="CC-BY-SA" width="100" /></a> [CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

Sorgenti [Marp](https://marp.app/) su https://github.com/matteodellamico/os_slides

Fonte: [*Scheduling: The Multi-Level Feedback Queue*](https://pages.cs.wisc.edu/~remzi/OSTEP/cpu-sched-mlfq.pdf), capitolo 8 di [*Operating Systems: Three Easy Pieces*](http://pages.cs.wisc.edu/~remzi/OSTEP/), di Remzi H. Arpaci-Dusseau e Andrea C. Arpaci-Dusseau.

---

<!-- Corbato et al. Compatible Time-Sharing System (CTSS), Turing award -->

# Mucche non più sferiche

![bg right:40%](https://c.pxhere.com/photos/c9/3d/cow_face_farm_nose_close_macro_animal_cattle-1265858.jpg!d)

Finora abbiamo fatto un'ipotesi non realistica: che lo scheduler **conoscesse la durata** di processi o CPU burst.

Vedremo come creare uno scheduler **reale** che ottiene un buon compromesso tra
- tempo di risposta
- turnaround time

Nel tempo, lo scheduler **impara** il comportamento dei processi.

---

<!-- _class: design -->

<!-- Argomento del liceo classico -->

<!-- Q: esempi? -->

# Design tip: imparare dal passato

![bg left:40%](https://c.pxhere.com/photos/75/fa/greece_athens_acropolis_history_historical_temple_touristic_old-639003.jpg!s1)

Come e più degli esseri umani, i sistemi informatici sono **prevedibili**.

Spesso il **comportamento futuro** sarà **simile a quello passato**.

Esempi:
 * cache
 * branch prediction

---

<!--Molte variazioni sul tema. Ne vedremo una semplice.-->

# Multi-Level Feedback Queue (MLFQ)

![bg right:40%](images/queues.png)

Idea di base: diversi **livelli di priorità**, con **una coda ciascuno**.

Regola di scheduling:
1. scegli la **coda non vuota** con **priorità più alta**
2. esegui in **round robin** i processi nella coda

I processi **cambiano coda** in base al loro comportamento (*feedback*).

---

# Perdere priorità

![bg right:30% demoted process 90%](images/mlfq_demote.svg)

Ogni job (processo) ha un ***allotment*** (assegnazione di CPU time)

- All'avvio, viene messo nella **coda di priorità più alta**
- Quando **esaurisce l'allotment**, scende di una coda
- Se un job **cede la CPU** (es.: I/O), l'allotment viene **resettato**

---

# Esempi

![w:800px center](images/mlfq_examples.svg)

Processi **brevi** (sinistra) e **interattivi** (I/O frequente, destra) hanno **priorità alta**.

* Ci sono casi in cui un questo scheduler potrebbe funzionare male?

---

# Casi da cui difendersi

- **Starvation**: un processo a bassa priorità potrebbe non essere mai eseguito
  - In un sistema batch, solo se le risorse richieste sono superiori alle capacità del sistema
  - In un sistema interattivo, i processi possono "espandersi" fino a occupare tutte le risorse disponibili

* **Cambio di comportamento**: un processo ***"CPU-bound"*** (il collo di bottiglia delle performance è la CPU) può passare a diventare ***"I/O-bound"*** (e viceversa)

* **Processi maligni**
  * Fare una richiesta di I/O quando l'allotment sta per finire

---

<!-- _class: design -->

![bg left:40%](https://images.rawpixel.com/image_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI1LTA5L3NyLWltYWdlLTI5MDgyMDI1LWFtMDUtcy0xMDcxLmpwZw.jpg)

# Design tip: lo scheduler può essere attaccato

Stiamo lavorando per sistemi **multi-utente**
- Es.: cloud

Uno scheduler vulnerabile può essere usato per attacchi ***denial-of-service*** (DoS), monopolizzando la CPU.

Gli utenti non sono necessariamente **fidati**

---

# Difendersi dagli attacchi

![w:800px center](images/mlfq_security.svg)

Basta **non resettare l'allotment** (destra) quando un processo cede la CPU.

---

# Riguadagnare priorità

![w:700px center](images/mlfq_promote.svg)

Dopo un intervallo di tempo $S$, tutti i processi **ritornano alla coda di priorità più alta**.
- si evita la starvation
- se un processo **cambia comportamento**, lo scheduler si adatta

---

<!-- _class: design -->

# Design tip: costanti vudù

![bg right:40% 210%](https://static.wikia.nocookie.net/monkeyislandes/images/f/f4/Voodoo_MI1.jpg/revision/latest?cb=20121007100904&path-prefix=es)

MLFQ ha **molti parametri da configurare**:
- numero di code
- allotment (può variare per coda)
- intervallo $S$ per il reset

Trovare configurazioni efficaci è **difficile** e spesso **empirico**.

Se possibile, sistemi con meno parametri sono preferibili.

Il **machine learning** è una buona opzione per trovare buone configurazioni.

---

<!-- Solaris: 60 code, allotment da 20ms a qualche centinaio di ms, reset ogni secondo -->

# Configurazioni di MLFQ

![bg right:40% demoted process 90%](images/mlfq_tuning.svg)

Ci sono **molte varianti** di MLFQ.

- Allotment variable secondo la coda (destra) per minimizzare il response time sui processi interattivi
- Formule per calcolare la priorità in base alla CPU usata, che "decade" nel tempo
  - es., dimezzamento periodico
- Comandi utente (es.: `nice`) per personalizzare le priorità

---

# Riepilogo

Multi-Level Feedback Queue:
- code a **più livelli di priorità**
- adatta le priorità basandosi sul passato (**feedback**)

È un buon compromesso tra
- **turnaround time**, perché i processi brevi vengono eseguiti velocemente
- **tempo di risposta**, perché tutti i processi avanzano e quelli interattivi lo fanno più rapidamente

