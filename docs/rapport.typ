

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
Ce projet, réalisé dans le cadre du cours de développement et SGBD, consiste à développer un clone de "chat IA" fonctionnel et intégré à une base de données relationnelle robuste. Ce projet a pour objectif d'apprendre à utiliser les framework web laravel et Vue ainsi qu'évidemment la gestion de base de données solide.
== Technologies utilisées
=== Backend
- Laravel 13.13.0
- Sqlite pour le local mais PostgreSQL envisagé pour le dépoloiement
- ORM eloquent : l'#glossaire(<glossaire:orm>, "ORM") natif de Laravel, chaque table possède un modèle et permet également de gérer les relations entre les tables. Il permet également de faire de l'#glossaire(<glossaire:eager_loading>, "eager loading")

=== Frontend
- Vue 3.5.35
- Inertia.js: permet de faire des pages dynamiques sans devoir recharger toute la page
- Tailwind

=== Intégration IA
- API d'#text(blue)[#link("https://openrouter.com")]

= Thème et identité
== Thème choisi
Comme le titre le décrit, c'est jsute un chat ia normal qui répond aux questions des utilisateurs, seulement plus on intéragit avec lui, plus il sombre dans la folie, comme pourrait le faire un personnage lovecraftien.
Ainsi, au fil de la discussion, il devient incohérent, oublie/rajoute des mots et divague. L'ui change également en réponse, le titre passe donc de "chat normal" à "chat anormal", un gradient rouge s'applique sur les bords pour faire un effet tunnel, si on parle assez le fond change de couleur pour donner une impression de bug.
//TODO 3 cpatures pour interface

== Personalitation de l'ia
Un bouton en bas à gauche permet de configurer à l'aide d'une modale comment nous répond l'ia:
- *Emojis* : si on veut des réponses avec des smileyrs
- *Ton* : si on veut que l'ia prenne un ton formel, décontracté, normal ou neutre
- *Longueur des réponses* : pour configurer si on veut des réponses courtes ou longes

Dans cette même modale, on peut également définir des racourcis que l'utilisateur peut configurer.
Par exemple : `/corrige` = "corrige moi l'orthographe et la syntaxe" \
Ainsi lorsque l'utilisateur fera `/corrige jadorre lé fruit` le site convertira le /corrige et l'assistant corrigera.
//TODO image configuration + lien

== Branding
J'ai grandement utilisé claude pour le Tailwind et il m'a aidé à mieux faire les vues, ainsi on se retrouve avec un thème assez sobre mais qui se transforme ensuite en interface chargé marquant la folie de l'ia. J'utilie les icones sobres fournis par laravel.
//TODO lien avec image en haut

= Modèle de données & architecture
== Diagrame de classe
//TODO diagramme
== tables et relations
=== table User
La table user contient les différentes informations de connexion, le nom qui est également utilisé par le systeme prompt(/*TODO link vers gloassarie)*/) l'ia favorite pour choisir l'ia par défaut lorsqu'on fait un nouvea chat et enfin les raccourcis configurables, elle ont une structure json car étant donné que c'est tout le temps une structure ["command": "...", "instruction" : "..."], c'est facilment maintenable et ça m'évite de créer une table annexe
=== table AoSetting
cette table sert à configurer comment l'ia nous répond, j'ai choisi de faire une table séparé plutôt qu'un json pour ces paramteres car elles peuvent changer, c'est donc plus maintenable, accesible et scalable, il ya donc le setting avec sa valeur.
*clé étrangère* vers user afin que chaque utilisateur aie ses paramètres
la relation est User "1" --> "0..\*" Ai Setting pour simplifier mais devrait être User "1" --> "{{nombre de settings}}..\*" Ai Setting


=== table Conversaton
Celle-ci permetra d'afficher les conversations sous forme de liste, on y retrouve, le titre, un autre champ ia favorite pour une discussion précise qui prendra le pas sur celle par défaut dans la table user. On y voit aussi le niveau d'insanité qui modifie le comportement de l'ia ainsi que l'ui, ce champ est dans cette table et pas une autre car j'ai choisi que l'ia devient reset quand on change de conversation. le dernier champ important est updated_at qui permet de trier les conversations pour mettre celle avec l'avtivité la plus récente en avant.
*clé étrangère* vers user afin de voir toutes les conversations d'un utilisateur et les rendre privés pour ce dernier
la relation est User "1" --> "0..\*" conversation car l'utilsateur n'a pas de conversation quand il vient de créer son compte


=== table Message
Avec la table message, nous avons le contenu de chaque message ainsi que le role qui est soit "assitant" soit "user" pour aider à la disposition dans l'interface, dans la même optique le champ created_at permet de connaitre l'ordre des messages
*clé étrangère* vers conversation pour reconstituer l'historique de la communction avec l'assitant intéligent
la relation est Conversation "1" --> "1..\*" Message car une conversation n'est créé que lorsque le premier message est entrée

=== table image
Elle peremt de stocker les images avec un url64/*TODO vérfierp puis mettre à jour quand en place*/ et un placeholder si l'image ne charge pas
*clé étrangère* vers conversation pour reconstituer l'historique de la communction avec l'assitant intélige
la relation est Conversation "1" --> "0..\*" Image car une conversation n'est pas obligé d'avoir une image

== Constraintes
Toutes les talbes ont la contrainte deleteOnCascade quand elle ont une foreign key afin de ne pas surcharger la bdd.
Par exemple, lorsque conversation est supprimer ça delete les message en deleteOnCascade
//TODO ajouter screen + glossaire pour delete on cascade

== documentation du code
//TODO compléter pour le moemnt pas de docs

== diagrammes complémentaires
//TODO pourquoi pas un séquence mais bon boring en vrai

= Fonctionnalités implémentés
== Focntionnalités obligatoires
=== sélecteur de modèles
//TODO capture
=== Historique + titre auto
//TODO capture
=== Streaming
//TODO capture
=== Instructions personnalisées
//TODO capture

== Focntionnalités supplémentaires
- on peut choisir l'ia favorite par discussion et par user
- l'ia a un comportement en fonction de la longueur de la discussion
-//TODO ajouter fonctionnalités dans le todo readme

= Difficultés rencontrés
J'ai tenu un journal de tout ce que j'ai fait dans docs/tutorial.md la plupart des difficultés peuvent être voir la bas mais voici u nexemple
//TODO ajouter un truc cool avec capture

= Tests
// TODO fair etest

= Utilisation de l'ia
- Corrction orthographe et syntaxe de rapport, readme, tutorial. J'écris tout moi même puis je demande à l'ia de corriger en gardant mes tournures de phrases et je vérifie après
- Tutoriels: quand il y a un truc que je ne sais pas faire, je lui demande de me faire un tuto sans donner les réponses, je lui demande d'attendre le code pour validation de ce que j'ai fais à chaque fois
- adaptation du code: j'avais fait tout le controller moi-même mais lors de l'adptation pour le steaming je ne comprenais pas grand chose alors je l'ai utiliser pour qu'il m'aide à adpater le code du cours dans mon controller puis j'ai modifier ce controller pour comprendre
- test: j'ai entierement fait les test par ia, j'ai fait les seeders et factory moi-meme
- Tailwind : le tailwind a également été fait par ia, je modifiais juste quelques tailles/couleurs par la suite
- Vue : il m'a grandement aidé a trouver les balises et parametres pour avoir ce que je veuxs

= utilisation
j'ai appris a utiliser un framework, appronfondis mes connaissances de requetes http qu'on avait vu dans le cours de reseau et l'utilisation de routes.


== Glossaire
#table(
  columns: (1fr, 2fr),
  [*Terme*], [*Définition*],

  [Eager Loading <glossaire:eager_loading>],
  [Technique d'optimisation Eloquent qui charge les relations associées en une seule requête SQL au lieu d'une requête par relation.],

  [ORM <glossaire:orm>],
  [Object-Relational-Mapper, il permet d'intéragir avec la base de données avec des objets au lieu de faire des requêtes SQL.],
)
