

#let projet(
  title: "",
  subtitle: none,
  doctype: "Projet UML",
  author: "",
  school: "",
  branch: "",
  academic-year: "",
  mentors: (),
  footer-text: "",
  accent: rgb("#6e1423"), // bordeaux sobre — modifiable
  body,
) = {
  set document(title: title, author: author)
  set text(font: "Latin Modern Roman", size: 11pt, lang: "fr")
  set par(justify: true, leading: 0.72em, first-line-indent: (amount: 1.2em, all: true))

  let spaced(it) = smallcaps(text(tracking: 1.6pt)[#it])

  // -------- PAGE DE GARDE --------
  page(
    margin: (top: 3.2cm, bottom: 3.2cm, x: 3cm),
    header: none,
    footer: none,
  )[
    #set align(center)
    #set par(first-line-indent: 0pt, justify: false)

    #spaced(text(size: 12pt)[#school])
    #if branch != "" [
      #v(0.35em)
      #text(size: 10.5pt, style: "italic", fill: luma(90))[#branch]
    ]

    #v(1fr)

    // Bloc titre encadré de filets fins
    #line(length: 100%, stroke: 0.6pt + accent)
    #v(0.9cm)
    #text(size: 15pt, fill: accent)[#spaced(doctype)]
    #v(0.7cm)
    #text(size: 30pt, weight: "regular")[#title]
    #if subtitle != none [
      #v(0.5cm)
      #text(size: 15pt, style: "italic", fill: luma(70))[#subtitle]
    ]
    #v(0.9cm)
    #line(length: 100%, stroke: 0.6pt + accent)

    #v(1fr)

    #spaced(text(size: 13pt)[#author])
    #if mentors.len() > 0 [
      #v(1cm)
      #text(size: 10pt, fill: luma(80))[
        #emph[Sous la supervision de] #linebreak()
        #mentors.join(linebreak())
      ]
    ]

    #v(1.2cm)
    #text(size: 11pt, fill: luma(60))[Année académique #academic-year]
  ]

  // -------- CORPS DU DOCUMENT --------
  set page(
    margin: (top: 2.6cm, bottom: 2.6cm, x: 3cm),
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 9pt, style: "italic", fill: luma(110))
        grid(
          columns: (1fr, auto),
          align: (left, right),
          [#title], [#spaced(text(size: 8pt)[#school])],
        )
        v(-0.4em)
        line(length: 100%, stroke: 0.4pt + luma(160))
      }
    },
    footer: context {
      set text(size: 9pt, fill: luma(110))
      line(length: 100%, stroke: 0.4pt + luma(160))
      v(0.2em)
      grid(
        columns: (1fr, auto),
        align: (left, right),
        text(style: "italic")[#footer-text], counter(page).display("1 / 1", both: true),
      )
    },
  )
  counter(page).update(1)

  set heading(numbering: "1.1")
  show heading.where(level: 1): it => {
    set text(size: 15pt, weight: "regular", fill: accent)
    block(above: 1.5em, below: 1em)[
      #spaced[#counter(heading).display() #h(0.6em) #it.body]
    ]
  }
  show heading.where(level: 2): it => {
    set text(size: 12pt, weight: "bold", fill: luma(40))
    block(above: 1.2em, below: 0.8em)[
      #counter(heading).display() #h(0.5em) #it.body
    ]
  }

  set table(
    stroke: (x, y) => (
      top: if y == 0 { 0.7pt + accent } else { 0.3pt + luma(180) },
      bottom: 0.3pt + luma(180),
    ),
    fill: (x, y) => if y == 0 { accent.lighten(90%) },
  )

  // Légende des figures
  show figure.caption: it => {
    set text(size: 9.5pt, style: "italic", fill: luma(70))
    it
  }

  // -------- TABLE DES MATIÈRES --------
  {
    set par(first-line-indent: 0pt)
    show outline.entry.where(level: 1): it => {
      v(0.5em)
      strong(it)
    }
    text(size: 15pt, weight: "regular", fill: accent)[#spaced[Table des matières]]
    v(0.8em)
    outline(title: none, indent: auto, depth: 2)
    v(1.2em)
    text(size: 15pt, weight: "regular", fill: accent)[#spaced[Table des figures]]
    v(0.8em)
    outline(title: none, target: figure.where(kind: image))
  }
  pagebreak()

  body
}

// ============================================================
//  CONFIGURATION DU DOCUMENT
// ============================================================
#let glossaire(label, content) = text(red, link(label)[#content])
#show: projet.with(
  title: [Chat Normal],
  subtitle: "SGBD",
  doctype: "Projet de développement ",
  author: "van der Veen Georgé",
  school: "Ifosup Wavre",
  // branch: "Conception et développement d'applications",
  academic-year: "2025-2026",
  footer-text: "van der Veen Georgé",
)

= Introduction
Ce projet, réalisé dans le cadre du cours de développement et SGBD, consiste à développer un clone de « chat IA » fonctionnel et intégré à une base de données relationnelle robuste. Il a pour objectif d'apprendre à utiliser les frameworks web Laravel et Vue, ainsi que la gestion d'une base de données solide.

== Technologies utilisées
=== Backend
- Laravel 13.13.0
- SQLite en local, mais PostgreSQL envisagé pour le déploiement.
- ORM Eloquent : l'#glossaire(<glossaire:orm>, "ORM") natif de Laravel. Chaque table possède un modèle, ce qui permet aussi de gérer les relations entre les tables. Il permet également de faire de l'#glossaire(<glossaire:eager_loading>, "eager loading").

=== Frontend
- Vue 3.5.35
- Inertia.js : permet de faire des pages dynamiques sans devoir recharger toute la page
- Tailwind
- shadcn-vue : composants d'interface préstylisés

=== Intégration IA
- API d'#text(blue)[#link("https://openrouter.com")]

= Thème et identité
== Thème choisi
Comme son titre l'indique, c'est juste un chat IA normal qui répond aux questions des utilisateurs. Seulement, plus on interagit avec lui, plus il sombre dans la folie, comme le ferait un personnage lovecraftien. Ainsi, au fil de la discussion, il devient incohérent, oublie ou rajoute des mots, et divague. L'interface change également en réponse : le titre passe de « Chat Normal » à « Chat Anormal », un gradient rouge s'applique sur les bords pour créer un effet tunnel, et si l'on parle assez longtemps, le fond change de couleur pour donner une impression de bug.
//TODO 3 captures pour interface

== Personnalisation de l'IA
Un bouton en bas à gauche permet de configurer, à l'aide d'une modale, la façon dont l'IA nous répond :
- *Emojis* : si l'on veut des réponses avec des smileys
- *Ton* : si l'on veut que l'IA prenne un ton formel, décontracté, normal ou neutre
- *Longueur des réponses* : pour configurer si l'on veut des réponses courtes ou longues

Dans cette même modale, on peut également définir des raccourcis personnalisables.
Par exemple : `/corrige` = « corrige-moi l'orthographe et la syntaxe » \
Ainsi, lorsque l'utilisateur écrira `/corrige jadorre lé fruit`, le site convertira le `/corrige` et l'assistant corrigera la phrase.
//TODO image configuration + lien

== Branding
J'ai grandement utilisé Claude pour le Tailwind ; il m'a aidé à améliorer les vues. On se retrouve ainsi avec un thème assez sobre, qui se transforme ensuite en une interface chargée marquant la folie de l'IA. J'utilise les icônes sobres fournies par Laravel.
//TODO lien avec image en haut

= Modèle de données & architecture
== Diagramme de classe
//TODO diagramme

== Tables et relations
=== Table User
La table `user` contient les différentes informations de connexion, le nom (également utilisé par le system prompt), l'IA favorite (pour choisir l'IA par défaut lors d'un nouveau chat) et enfin les raccourcis configurables. Ceux-ci ont une structure JSON : comme c'est toujours une structure `{ "command": "...", "instruction": "..." }`, c'est facilement maintenable et cela m'évite de créer une table annexe.

=== Table AiSetting
Cette table sert à configurer la façon dont l'IA nous répond. J'ai choisi de faire une table séparée plutôt qu'un JSON pour ces paramètres car ils peuvent évoluer ; c'est donc plus maintenable, accessible et scalable. On y trouve donc le `setting` avec sa `value`.
*Clé étrangère* vers `user`, afin que chaque utilisateur ait ses propres paramètres.
La relation est `User "1" --> "0..*" AiSetting` pour simplifier, mais devrait être `User "1" --> "{nombre de settings}..*" AiSetting`.

=== Table Conversation
Celle-ci permettra d'afficher les conversations sous forme de liste. On y retrouve le titre, un autre champ « IA favorite » pour une discussion précise (qui prendra le pas sur celle par défaut de la table `user`). On y voit aussi le niveau d'insanité, qui modifie le comportement de l'IA ainsi que l'interface ; ce champ est dans cette table et pas une autre car j'ai choisi que l'IA se réinitialise quand on change de conversation. Le dernier champ important est `updated_at`, qui permet de trier les conversations pour mettre celle dont l'activité est la plus récente en avant.
*Clé étrangère* vers `user`, afin de voir toutes les conversations d'un utilisateur et de les rendre privées.
La relation est `User "1" --> "0..*" Conversation` car l'utilisateur n'a aucune conversation quand il vient de créer son compte.

=== Table Message
Avec la table `message`, nous avons le contenu de chaque message ainsi que le rôle, qui est soit « assistant » soit « user », pour aider à la disposition dans l'interface. Dans la même optique, le champ `created_at` permet de connaître l'ordre des messages.
*Clé étrangère* vers `conversation`, pour reconstituer l'historique de la communication avec l'assistant.
La relation est `Conversation "1" --> "1..*" Message` car une conversation n'est créée que lorsque le premier message est entré.

=== Table Image
Elle permet de stocker les images avec une URL (en base64) et un placeholder si l'image ne charge pas.
//TODO vérifier puis mettre à jour quand en place
*Clé étrangère* vers `conversation`.
La relation est `Conversation "1" --> "0..*" Image` car une conversation n'est pas obligée d'avoir une image.

== Contraintes
Toutes les tables ayant une clé étrangère possèdent la contrainte `deleteOnCascade`, afin de ne pas surcharger la base de données. Par exemple, lorsqu'une conversation est supprimée, cela supprime les messages en cascade.
//TODO ajouter screen + glossaire pour delete on cascade

== Documentation du code & gestion des erreurs
Les entrées utilisateur sont validées dans les contrôleurs via `$request->validate(...)`, qui rejette toute requête mal formée avant traitement. L'accès aux conversations est protégé par `abort_unless($conversation->user_id === auth()->id(), 403)`, garantissant qu'un utilisateur ne peut consulter ou supprimer que ses propres conversations. Les valeurs potentiellement absentes (comme le niveau d'insanité d'une conversation fraîchement créée) sont sécurisées par des valeurs par défaut.
//TODO compléter avec extraits de code annotés vérifier ce qui'l y a écrit en haut

== Diagrammes complémentaires
//TODO pourquoi pas un séquence mais bon boring en vrai

= Fonctionnalités implémentées
== Fonctionnalités obligatoires
=== Sélecteur de modèles
//TODO capture
=== Historique + titre auto
//TODO capture
=== Streaming
//TODO capture
=== Instructions personnalisées
//TODO capture

== Fonctionnalités supplémentaires
- On peut choisir l'IA favorite par discussion et par utilisateur
- L'IA a un comportement qui évolue en fonction de la longueur de la discussion
//TODO ajouter fonctionnalités dans le TODO du README

= Difficultés rencontrées
J'ai tenu un journal de tout ce que j'ai fait dans `docs/tutorial.md` ; la plupart des difficultés peuvent y être consultées, mais en voici un exemple.
//TODO ajouter un truc cool avec capture

= Tests
//TODO faire test

= Utilisation de l'IA
- *Correction* orthographe et syntaxe du rapport, du README et du tutoriel. J'écris tout moi-même, puis je demande à l'IA de corriger en gardant mes tournures de phrases, et je vérifie après.
- *Tutoriels* : quand il y a quelque chose que je ne sais pas faire, je lui demande de me faire un tutoriel sans donner les réponses ; je lui demande d'attendre mon code pour validation à chaque étape.
- *Adaptation du code* : j'avais fait tout le contrôleur moi-même, mais lors de l'adaptation pour le streaming je ne comprenais pas grand-chose, alors je l'ai utilisé pour m'aider à adapter le code du cours dans mon contrôleur, puis j'ai modifié ce contrôleur pour comprendre.
- *Tests* : j'ai entièrement fait les tests par IA ; j'ai fait les seeders et factories moi-même.
- *Tailwind* : le Tailwind a également été fait par IA ; je modifiais juste quelques tailles et couleurs par la suite.
- *Vue* : il m'a grandement aidé à trouver les balises et paramètres pour obtenir ce que je voulais.

= Réflexion, améliorations & conclusion
Ce projet m'a permis d'apprendre à utiliser un framework web complet, d'approfondir mes connaissances des requêtes HTTP vues dans le cours de réseau, et de mieux comprendre l'utilisation des routes et d'un ORM.
.
En conclusion, ce projet m'a fait progresser autant sur la conception d'une base de données relationnelle cohérente que sur le développement front-end et l'intégration d'une API d'IA en streaming.

== Glossaire
#table(
  columns: (1fr, 2fr),
  [*Terme*], [*Définition*],

  [Eager Loading <glossaire:eager_loading>],
  [Technique d'optimisation Eloquent qui charge les relations associées en une seule requête SQL au lieu d'une requête par relation.],

  [ORM <glossaire:orm>],
  [Object-Relational Mapper : il permet d'interagir avec la base de données via des objets au lieu d'écrire des requêtes SQL.],
)
