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

# Scheduling: introduzione

Matteo Dell'Amico

<a href="https://creativecommons.org/licenses/by-sa/4.0/"><img src="https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-sa.png" alt="CC-BY-SA" width="100" /></a> [CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

Sorgenti [Marp](https://marp.app/) su https://github.com/matteodellamico/os_slides

Fonte: [*Scheduling: Introduction*](https://pages.cs.wisc.edu/~remzi/OSTEP/cpu-sched.pdf), capitolo 7 di [*Operating Systems: Three Easy Pieces*](http://pages.cs.wisc.edu/~remzi/OSTEP/), di Remzi H. Arpaci-Dusseau e Andrea C. Arpaci-Dusseau.

---

![bg right:45% Kat Walsh, CC BY-SA 3.0 &lt;http://creativecommons.org/licenses/by-sa/3.0/&gt;, via Wikimedia Commons](https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Wikimania2007_everythings_a_wiki.jpg/256px-Wikimania2007_everythings_a_wiki.jpg?20111209201030)

# Politiche di scheduling

Abbiamo visto i **meccanismi** per il time sharing (syscall, interrupt, context switch).

Ora vediamo le **politiche**: come scegliere quale processo eseguire.

Lo scheduling è una disciplina non solo informatica, ma ad esempio:
- nel project management
- nei sistemi di trasporto
- nelle fabbriche

---

<!-- ovviamente ci sono tradeoff tra i vari obiettivi -->

![bg left:30%](https://www.pngall.com/wp-content/uploads/5/Hourglass-PNG-Free-Image.png)

# Metrica: turnaround time

Una **metrica** per valutare le politiche di scheduling.

Per ogni processo:

$$T_{\mathit{turnaround}} = T_{\mathit{completamento}} - T_{\mathit{arrivo}}$$

Ne calcoliamo la media e la usiamo per valutare l'**efficienza**.
- Per il momento limitiamoci a pensare a processi di tipo **batch** (non interattivi).

Ce ne sono molte altre, ad esempio per valutare **reattività** e **equità**.

---

![bg right:45%](images/fifo.png)

# First In, First Out (FIFO)

<!-- AKA First Come, First Served (FCFS) -->
<!-- esempio 1: A, B, C arrivano quasi insieme al secondo 0. Tutti e tre richiedono 10s. -->
<!-- D: come facciamo a rendere FIFO terribile? A: R ora richiede 100s. -->

Politica: scegli sempre **il primo processo che è arrivato**.

La **coda** si implementa semplicemente
- es.: linked list

* Proviamo alcuni esempi. Dov'è che FIFO potrebbe comportarsi male?

---

![bg left:50%](images/convoy.jpg)

# Effetto convoglio (*convoy effect*)

![w:500px](images/fifo-diagram2.jpg)

Turnaround time medio:

$$\frac{100 + 110 + 120}{3} = 110$$

* Processi brevi sono bloccati dietro a processi lunghi
* Come fare meglio?

---

<!-- SJF è ottimale se tutti i job arrivano assieme -->

![bg right:40%](https://live.staticflickr.com/50/149575038_62529fa117.jpg)

# Shortest Job First (SJF)

Politica: esegui il processo con il **tempo di esecuzione più breve**, fino alla fine.

![w:500px](images/sjf_diagram.svg)

Turnaround time medio:
$$\frac{10 + 20 + 120}{3} = 20$$

* Come implementare SJF?
  * coda con priorità (es.: heap binario)

---

<!-- _class: aside -->

![bg left:40%](images/msadu.jpg)

# ...ma come sapere quanto durerà un processo?

Il SO, effettivamente, **non lo sa**.

Situazione che ricorda la [barzelletta delle mucche sferiche](https://it.wikipedia.org/wiki/Mucca_sferica): per risolvere un problema, facciamo **presupposizioni non realistiche**.

Per il momento **portiamo pazienza**: vedremo poi come ottenere risultati simili in **situazioni realistiche**.

---

![bg right:50%](images/convoy.jpg)


# E se B e C arrivano dopo A?

Supponiamo che A arrivi al tempo 0, e B e C al tempo 10.

![w:500px](images/sjf_diagram2.svg)

Siamo tornati all'**effetto convoglio**.

Come fare meglio?

---

# Shortest Remaining Processing Time (SRPT)

*(aka Shortest Time-to-Completion First (STCF) e Preemptive Shortest Job First (PSJF))*

Politica: esegui il processo con il **tempo di esecuzione residuo più breve**.

Se arriva un nuovo processo con tempo più breve, **interrompilo** (***preempt***) e fai partire il nuovo.

![w:500px center](images/srpt_diagram.svg)

SRPT è **ottimale** per ottimizzare il turnaround time medio.

---

![bg left:40%](https://upload.wikimedia.org/wikipedia/commons/d/d2/London_2012_Olympic_100m_final_start.jpg)

# Metrica: tempo di risposta

Consideriamo ora processi **interattivi**.

In questo caso, abbiamo utenti che vogliono ottenere riposte **rapide**.

Nuova metrica: **tempo di risposta**.

$$T_{\mathit{risposta}} = T_{\mathit{prima\ risposta}} - T_{\mathit{arrivo}}$$

Le politiche viste finora hanno **tempi di risposta alti**.

Come migliorare le cose?

---

<!-- etimologia: ruban rond -->

![bg right:40%](https://upload.wikimedia.org/wikipedia/commons/a/a1/Round_Robin_image.jpg)

# Round Robin (RR)

Politica: assegna a ogni processo un **time slice** (es.: 100ms).
- La time slice deve essere un multiplo dell'intervallo di timer (es.: 10ms).

![w:500px](images/rr_diagram.svg)

Si **ottimizza il tempo di risposta**, al costo di un turnaround time più alto.

---

# Round Robin vs SRPT

![w:500px](images/rr_diagram.svg) &emsp; ![w:500px right](images/srpt_diagram2.svg)

Tempo di risposta: RR $\frac{0+1+2}{3}=1$ vs SRPT $\frac{0+5+10}{3}=5$

Turnaround time: RR $\frac{13+14+15}{3}=14$ vs SRPT $\frac{5+10+15}{3}=10$

* Round robin spende anche più tempo in overhead
  * context switch
  * coerenza di cache, branch predictor...

---

# Tempo di risposta e turnaround time

![bg left:40% 100%](images/scale.svg)

Purtroppo, **non possiamo ottimizzare entrambe le metriche**.

Round Robin dà la priorità alla reattività, SRPT al turnaround time.

Tipico esempio di **compromesso** (*trade-off*).

Vedremo politiche che **bilanciano i due obiettivi**.

---

# Gestire l'input/output

Solo un processo inutile non fa I/O: farebbe calcoli senza dare risultati.

I processi vengono suddivisi in **sotto-compiti**: **CPU burst** e **I/O burst**.

Strategia comune: schedulare i singoli **CPU burst**, e schedulare altri processi quando quello in esecuzione si blocca.

![w:500px center](images/io_diagram.svg)

Anche SRPT diventa **reattivo** con i processi interattivi che usano spesso l'I/O.

---

# Riassunto

Abbiamo visto alcune **politiche di scheduling** classiche FIFO, SJF, SRPT, RR.

Inoltre, abbiamo discusso come gestire i processi che fanno I/O frequentemente, suddividendoli in **sotto-compiti** e schedulando i singoli **CPU burst**.

SRPT sembra una scelta eccellente, ma resta l'ovvio problema: **come fare dato che non sappiamo quanto durerà un processo o un CPU burst?**

Nelle prossime lezioni vedremo come gestire questo problema.