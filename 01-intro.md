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


---

# **Sistemi operativi: introduzione**

Matteo Dell'Amico

<a href="https://creativecommons.org/licenses/by-sa/4.0/"><img src="https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-sa.png" alt="CC BY-SA" width="100" /></a> [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

Sorgenti [Marp](https://marp.app/) su https://github.com/matteodellamico/os_slides

---

# Fonte

[*Operating Systems: Three Easy Pieces*](http://pages.cs.wisc.edu/~remzi/OSTEP/), di Remzi H. Arpaci-Dusseau e Andrea C. Arpaci-Dusseau.

Libro **gratuito**. Tre temi: **virtualizzazione**, **concorrenza**, **persistenza**. Noi vedremo **virtualizzazione** e **persistenza**.

Queste slide sono basate sul primo capitolo, [*Introduction to Operating Systems*](https://pages.cs.wisc.edu/~remzi/OSTEP/intro.pdf).

![bg left 70%](https://pages.cs.wisc.edu/~remzi/OSTEP/book-cover-two.jpg)

---

# Un programma in esecuzione

Quando un programma è in esecuzione, per **miliardi** di volte al secondo il processore:
- legge un'istruzione dalla memoria (*fetch*)
- decodifica l'istruzione (*decode*)
- esegue l'istruzione (*execute*)

Lo sappiamo: è l'architettura di **von Neumann**.

![bg right:40%](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/JohnvonNeumann-LosAlamos.gif/256px-JohnvonNeumann-LosAlamos.gif)

---

# Ma...

Le istruzioni nel nostro eseguibile sono scritte come se fossero **l'unico programma in esecuzione sul computer**.
- Questo **facilita moltissimo** chi scrive il codice.

Com'è possibile che molti programmi (molti più delle CPU disponibili) vengano eseguiti **contemporaneamente** sullo stesso computer?

![bg right:30% opacity:0.2](https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Question_Mark.svg/480px-Question_Mark.svg.png)

---

# Virtualizzazione

Tecnica generica che permette di scrivere software come se avesse a disposizione **tutte** le risorse del computer, mentre in realtà sono **condivise** tra molti programmi.

Una risorsa fisica (CPU, memoria, disco, ...) viene **astratta** in modo da sembrare una risorsa **virtuale** dedicata. È per meccanismi di questi tipo che si parla di **macchine virtuali**.

In questo corso, vedremo come funzionano la virtualizzazione della **CPU** e della **memoria**.

---

# Non solo virtualizzazione

Un sistema operativo fornisce anche:
- una libreria di **chiamate di sistema** (***system calls***) per accedere alle risorse della macchina virtuale;
- meccanismi di **gestione** delle risorse (CPU, memoria, disco, ...), per fare in modo che più programmi possano condividerle in modo **sicuro** e **efficiente**.

---

# Virtualizzazione della CPU: `cpu.c`

```c
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

int main(int argc, char *argv[])
{
    if (argc != 2) {
	fprintf(stderr, "usage: cpu <string>\n");
	exit(1);
    }
    char *str = argv[1];

    while (1) {
	printf("%s\n", str);
	Spin(1);
    }
    return 0;
}
```

(da https://github.com/remzi-arpacidusseau/ostep-code/tree/master/intro)

---

# CPU virtualizzata

```
$ ./cpu "A" & ./cpu "B" & ./cpu "C" & ./cpu "D" &
A
C
D
B
A
C
D
B
A
C
...
```

Anche se `Spin` è una **busy wait** (non fa altro che tenere occupata la CPU), i processi si alternano (anche quando sono meno delle CPU attive: provate, su Linux, con `taskset`).

---

# Virtualizzazione della memoria: `mem.c`

```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

int main(int argc, char *argv[]) {
    if (argc != 2) { 
	fprintf(stderr, "usage: mem <value>\n"); 
	exit(1); 
    } 
    int *p; 
    p = malloc(sizeof(int));
    assert(p != NULL);
    printf("(%d) addr pointed to by p: %p\n", (int) getpid(), p);
    *p = atoi(argv[1]); // assign value to addr stored in p
    while (1) {
	Spin(1);
	*p = *p + 1;
	printf("(%d) value of p: %d\n", getpid(), *p);
    }
    return 0;
}
```

---

# Memoria virtualizzata

```
$ setarch  -R ./mem 1 & setarch -R ./mem 100
[1] 34572
(34572) addr pointed to by p: 0x5555555592a0
(34573) addr pointed to by p: 0x5555555592a0
(34572) value of p: 2
(34573) value of p: 101
(34572) value of p: 3
(34573) value of p: 102
(34572) value of p: 4
(34573) value of p: 103
(34572) value of p: 5
(34573) value of p: 104
```

`setarch -R` disabilita l'ASLR (Address Space Layout Randomization), per cui i due processi vedono lo **stesso** indirizzo virtuale (0x5555555592a0) ma **puntano a locazioni di memoria fisica diverse**.

---

# Persistenza: `io.c`

```c
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>

int main(int argc, char *argv[]) {
    int fd = open("/tmp/file", O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    assert(fd >= 0);
    char buffer[20];
    sprintf(buffer, "hello world\n");
    int rc = write(fd, buffer, strlen(buffer));
    assert(rc == (strlen(buffer)));
    fsync(fd);
    close(fd);
    return 0;
}
```

---

# Persistenza e file system

C'è molta strada tra quello che l'hardware offre (scrivi certi dati su un blocco del disco) e le funzionalità offerte da un file system.

Vedremo anche questo.

![bg left:40%](https://ia800608.us.archive.org/14/items/HardDriveSpinning/Hard-Drive-450px.gif)
![bg right:40%](https://lh3.googleusercontent.com/blogger_img_proxy/AEn0k_uHZmak3vYdnRmPtSdXtPjbYpcamvvdaw83Taguef8zeXVGKbLK_bLzuhbVCoi540twu4t9KWXltuTCKvqVF7pIXUcNvSIPv7VK7n5qWVMAzeO-mYCYNJWStgaag3G6ouZkPevqkjuWMjLw7xZoNEKFa1k=s0-d)

---

# Riassumendo

Un sistema operativo fornisce:
- una **macchina virtuale** (virtualizzazione di CPU, memoria, disco, ...);
- una **libreria di chiamate di sistema** per accedere alle risorse della macchina virtuale;
- meccanismi di **gestione** delle risorse (CPU, memoria, disco, ...), per fare in modo che più programmi possano condividerle in modo **sicuro** e **efficiente**.

Farlo è complicato, e scopriremo insieme (pezzi di) come funziona.

---

# **Breve storia dei sistemi operativi**

![bg right:70%](https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Unix_history-simple.en.svg/1960px-Unix_history-simple.en.svg.png)

---

# 🔧 I primi computer
- **Non un vero sistema operativo**: solo delle librerie per funzioni più comuni
- Accesso diretto all'hardware
- **Job scheduling manuale**: operatori umani caricavano programmi uno alla volta

![bg right:50%](https://upload.wikimedia.org/wikipedia/commons/d/d3/Glen_Beck_and_Betty_Snyder_program_the_ENIAC_in_building_328_at_the_Ballistic_Research_Laboratory.jpg)

---

# Anni '60-'70: Mainframe

- Sistemi **multiutente**:
    - più utenti condividono lo stesso computer
    - ogni utente ha i suoi programmi e dati
- Nascono le **system call** per accedere alle risorse
- Il sistema operativo lavora in **modo kernel**, con accesso a tutto
- Gli utenti hanno accesso limitato, tramite le system call

![bg left:30%](https://c1.staticflickr.com/3/2164/1889691491_96fad6ee74_b.jpg)

---

# Minicomputer 

![bg right:50%](https://dave.cheney.net/wp-content/uploads/2017/12/PanelInCase_Side.jpg)

Macchine accessibili a organizzazioni più piccole

**Multiprogrammazione**: esecuzione simultanea di più programmi
- L'I/O era (ed è!) molto lento
- Si esegue altro mentre si aspetta l'I/O

Protezione della memoria e concorrenza

---

# Personal Computer

![bg left:50%](https://upload.wikimedia.org/wikipedia/commons/6/69/IBM_PC_5150.jpg)
![bg left:50%](https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Tux.svg/512px-Tux.svg.png)

Grosso passo indietro con i primi PC IBM: **MS-DOS**

Windows lentamente recupera le funzionalità dei minicomputer

Linux e Mac OS X sono eredi di Unix, storico OS per minicomputer.
