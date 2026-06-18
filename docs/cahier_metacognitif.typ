#set page(
  paper: "a4",
  margin: 2cm,
)
#set text(
  font: "Noto Sans",
  size: 11pt,
)

#show heading.where(level: 1): set text(size: 22pt, weight: "bold")
#show heading.where(level: 2): set text(size: 16pt, weight: "bold")

// Cases à cocher cohérentes : ☒ = coché, ☐ = vide
#let case(coche) = if coche [☒] else [☐]

#align(center)[= Cahier métacognitif]
#align(center)[
  *Usage de l'IA — Projet de développement (SGBD) — IDV3*
]

#v(1em)

== Partie 1 — Déclaration d'usage de l'IA

=== 1. Outil(s) utilisé(s)

J'ai utilisé Claude, c'est ce qui semblait me donner de meilleurs résultats.

#v(1.3em)
#line(length: 100%)
#v(0.8em)

=== 2. Niveau d'usage

Entoure ou indique le niveau :

#case(false) 0 (pas d'IA) #h(1em)
#case(false) 1 #h(1em)
#case(true) 2 #h(1em)
#case(false) 3 (coproduction encadrée)

#v(1em)

=== 3. Utilisation

#case(false) comprendre la consigne \
#case(false) chercher des idées \
#case(false) élaborer un plan / structurer \
#case(true) reformuler \
#case(true) corriger la langue \
#case(true) assistance au code (questions, autocomplétion) \
#case(false) vérifier la clarté d'un texte \
#case(true) autre : tutoriels

#v(1em)

=== 4. Démarche suivie

En général, quand je ne comprends pas un truc, je lui demande de me faire un tuto en me faisant réfléchir. Je l'ai également utilisé pour corriger orthographiquement et syntaxiquement le rapport, le `tutorial.md` et le `README.md`.

Les seules fois où je l'ai vraiment utilisé pour avoir de vrais bouts de code, c'était quand j'ai dû adapter le projet pour utiliser le streaming, pour faire tout le Tailwind et pour m'aider à faire les différentes Vue.

#pagebreak()

=== 5. Vérifications réalisées

J'ai regardé principalement le cours, la doc de Laravel pour certaines fonctions et les tutos d'OpenRouter.

#v(1em)

=== 6. Regard critique

*Ce que l'IA m'a apporté :*

Ça accélère beaucoup la création et ça permet de ne pas rester bloqué des heures sur un problème spécifique. Ça m'a également permis d'apprendre en m'aiguillant.

#v(4em)
#line(length: 100%)
#v(1em)

*Ses limites / erreurs éventuelles :*

Je trouve que ça reste quand même très peu organique. De plus, certains choix architecturaux, quand je lui demandais des tutos, étaient assez douteux.

#v(4em)
#line(length: 100%)
#v(1em)

=== 7. Contribution personnelle

C'est moi qui ai choisi le thème, et j'ai fait tout ce qui était backend moi-même (un peu moins le streaming), en particulier le controller où j'ai vraiment essayé de tout comprendre.

#v(5em)
#line(length: 100%)
#v(1em)

=== 8. Attestation

Je déclare que le travail remis respecte les consignes concernant l'usage de l'IA.

#v(2em)

Nom : Van der Veen #h(3cm) Date : 20 juin 2026

#v(2em)

#align(right)[
  _Canevas adapté de la charte d'établissement._
]
