

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
  title: [AI Chat\
    Rapport de projet],
  subtitle: "SGBD",
  doctype: "Projet de développement ",
  author: "van der Veen Georgé",
  school: "Ifosup Wavre",
  // branch: "Conception et développement d'applications",
  academic-year: "2025-2026",
  footer-text: "van der Veen Georgé",
)

= Introduction
Ce projet, réalisé dans le cadre du cours de développement et SGBD, consiste à développer un clone de "chat IA" fonctionnel et intégré à une base de données relationnelle robuste. Contrairement à de nombreux projets web basés sur des données éphémères, l'enjeu ici est de concevoir un schéma de base de données soigné qui garantit l'intégrité des données, l'efficacité des requêtes, et la scalabilité de l'application.

== Technologies utilisées
=== Backend
- Laravel 13.13.0
- //TODO base de données
- ORM eloquent : l'#glossaire(<glossaire:orm>, "ORM") natif de Laravel, chaque table possède un modèle et permet également de gérer les relations entre les tables. Il permet également de faire de l'#glossaire(<glossaire:eager_loading>, "eager loading")

=== Frontend
- Vue 3.5.35
- Inertia.js: permet de faire des pages dynamiques sans devoir recharger toute la page
- Tailwind

=== Intégration IA
- API d'#text(blue)[#link("https://openrouter.com")]

= Thème et identité
== Thème choisi
C'est un chat normal à première vue mais qui devient fou au fil de la discussion

== Personnalité de l'IA
L'utilisateur peut choisir la personnalité de l'IA grâce à un bouton qui ouvre une modale et lui permet de choisir des paramètre
//TODO image

== Modèle de données & architecture


== Glossaire
#table(
  columns: (1fr, 2fr),
  [*Terme*], [*Définition*],

  [Eager Loading <glossaire:eager_loading>],
  [Technique d'optimisation Eloquent qui charge les relations associées en une seule requête SQL au lieu d'une requête par relation.],

  [ORM <glossaire:orm>],
  [Object-Relational-Mapper, il permet d'intéragir avec la base de données avec des objets au lieu de faire des requêtes SQL.],
)
