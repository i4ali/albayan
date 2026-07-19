//
//  SurahFatihaDive.swift
//  AlBayan
//
//  Content for the "Inside the Surah - al-Fatiha" experience (the free flagship).
//  Rendered by DeepDiveView. Approved master script:
//  docs/plans/surah-experience/fatiha-sunni-script.md
//
//  English-first: every LocalizedText is a bare string literal (ur/ar fall back to en);
//  a later pass replaces them with LocalizedText(en:ur:ar:). Qur'an Arabic is verbatim
//  from the bundled quran_data.json (BOM stripped on 1:1). Ends on .closing.
//
//  Sunni-sourced: the division-of-the-prayer replies are from Sahih Muslim 395; the
//  straight-path narration is the parable of al-Nawwas ibn Sam'an (al-Tirmidhi 2859,
//  Musnad Ahmad); tafsir points trace to Ibn Kathir / al-Tabari / al-Qurtubi.
//

import SwiftUI

extension DeepDive {
    static let surahFatiha: DeepDive = DeepDive(
        id: "surah-fatiha",
        titleEn: "al-Fatiha",
        titleAr: "الْفَاتِحَة",
        subtitle: "The Opening - the prayer God taught you to pray",
        sfSymbol: "book.closed",
        estMinutes: 11,
        acts: [
            ActInfo(number: 1, ar: "الْحَمْد", tr: "al-Hamd", name: "The Praise"),
            ActInfo(number: 2, ar: "الِالْتِفَات", tr: "al-Iltifat", name: "The Turn"),
            ActInfo(number: 3, ar: "الصِّرَاط", tr: "al-Sirat", name: "The Path"),
        ],
        sections: [
            .open(
                kicker: "INSIDE THE SURAH",
                titleAr: "الْفَاتِحَة",
                titleEn: "al-Fatiha",
                subtitle: "The Opening",
                line: "Seven short verses. You have said them more times than any other words in your life - at the start of every prayer, every rak'ah, since the day you learned to pray. This is the surah you know entirely by heart. Here is the chance to finally hear it."
            ),
            .orientation(
                eyebrow: "Before you begin",
                promise: "They called it Umm al-Kitab, the Mother of the Book, and al-Sab al-Mathani, the seven oft-repeated verses God paired with the whole Qur'an. No prayer is complete without it. And it is built as a conversation: first you praise Him, then you turn to face Him, then you ask Him for the one thing you most need.",
                leaveWith: "You will leave knowing al-Fatiha not as an opening you rush through, but as the prayer God Himself taught you to pray - and knowing what He says back to you, line by line, every time you stand before Him."
            ),
            .act(
                act: 1, connector: nil,
                line: "Before you ask God for anything, al-Fatiha slows you down to remember who He is. Four names, four faces of the One you are about to speak to: the Merciful, the Lord, the Compassionate, the King of the Last Day. This is the half of the prayer that belongs to Him.",
                bridge: nil
            ),
            .verse(
                act: 1, tag: "In His Name", surah: 1, ayah: 1,
                arabic: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                translation: "In the name of Allah, the All-Merciful, the Ever-Merciful.",
                reference: "al-Fatiha · 1 : 1",
                reflection: "You open not with your own strength but by leaning on His name. And the very first thing He tells you about Himself is mercy, said two ways: al-Rahman, the mercy so vast it reaches every creature alive, believer or not; and al-Rahim, the mercy He keeps for those who turn back to Him. Ibn Kathir notes the two forms are deliberate - one is mercy overflowing and universal, the other mercy steady and enduring. And in a sacred hadith He says of Himself: My mercy precedes My wrath. You begin here."
            ),
            .verse(
                act: 1, tag: "All Praise", surah: 1, ayah: 2,
                arabic: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
                translation: "All praise is for Allah, Lord of all the worlds.",
                reference: "al-Fatiha · 1 : 2",
                reflection: "Not shukr, thanks for a gift received, but hamd - praise for who He is, whether or not you were given anything today. The scholars of the language drew the line: you thank someone for a favor, but you praise Him for His own perfection. And Rabb means more than Maker. Ibn Kathir, citing Ibn Abbas, reads it as the Lord and Master who owns all things and raises each one from a seed to its fullness - never creating and walking away, but sustaining every world, seen and unseen, breath by breath."
            ),
            .verse(
                act: 1, tag: "Mercy, Again", surah: 1, ayah: 3,
                arabic: "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                translation: "The All-Merciful, the Ever-Merciful.",
                reference: "al-Fatiha · 1 : 3",
                reflection: "He has just named Himself Lord of all the worlds - and before He names Himself King of the Day of Judgment in the very next breath, He says mercy again. Twice. Ibn Kathir reads the repetition as emphasis, not redundancy: lest you ever imagine His power is cold, mercy is placed ahead of sovereignty and judgment, so you meet the King of the Last Day already knowing how He rules. The throne of the universe is not a throne of fear."
            ),
            .verse(
                act: 1, tag: "King of the Day", surah: 1, ayah: 4,
                arabic: "مَٰلِكِ يَوْمِ ٱلدِّينِ",
                translation: "Master of the Day of Judgment.",
                reference: "al-Fatiha · 1 : 4",
                reflection: "And yet mercy is not the whole of it. He is also Malik - not an abstract force but a personal King who owns that Day, when every other crown is laid down and only His remains. Two readings were passed down from the Prophet ﷺ and both are recited - Malik, the King, and Maalik, the Owner - and both are true: He commands that Day and He owns it, with no rival. You will not stand before a system, but before Someone who knows you by name. Mercy and justice, held in one hand. This is the God you have been praising - and here the surah turns."
            ),
            .response(
                act: 1, replyingTo: "to your praise · 1 : 1-4",
                arabic: "حَمِدَنِي عَبْدِي",
                words: "“My servant has praised Me, extolled Me, and glorified Me.”",
                source: "Hadith Qudsi · Sahih Muslim",
                reflection: "In a sacred hadith recorded by Muslim, God says He divided this prayer between Himself and His servant. And He answers you line by line: when you give the praise, He says My servant has praised Me; when you name His mercy, He says My servant has extolled Me; when you own His kingship of that Day, He says My servant has glorified Me. The praise you thought rose and vanished into the air was heard - and given back to you, name by name."
            ),
            .act(
                act: 2,
                connector: "You have praised Him by every name - the Merciful, the Lord, the King of the Day.",
                line: "And now something changes. For four verses you spoke about God, in the third person, as if describing Someone far off. Here the surah does something the scholars call iltifat, the turn: you stop speaking about Him and begin speaking to Him. Knowledge becomes meeting.",
                bridge: nil
            ),
            .verse(
                act: 2, tag: "Face to Face", surah: 1, ayah: 5,
                arabic: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
                translation: "It is You we worship, and it is You we ask for help.",
                reference: "al-Fatiha · 1 : 5",
                reflection: "Iyyaka - You, and none but You - is placed first, so worship can point nowhere else. Ibn Kathir reads this word order as the heart of tawhid: by naming Him before the verb, the verse shuts every other door. And notice the order - worship before help. Al-Qurtubi saw manners in it: you do not come to God as a customer with a request, but as a servant who gives himself first, and only then asks. Notice too that it is we, not I: you never pray al-Fatiha alone, but standing inside the whole company of those who bow. This is the line God kept between Himself and His servant."
            ),
            .response(
                act: 2, replyingTo: "to the meeting point · 1 : 5",
                arabic: "بَيْنِي وَبَيْنَ عَبْدِي",
                words: "“This is between Me and My servant - and My servant shall have what he asked.”",
                source: "Hadith Qudsi · Sahih Muslim",
                reflection: "The one line He kept for the two of you together. And before you have even finished asking, the promise: you shall have what you asked."
            ),
            .act(
                act: 3,
                connector: "You have met Him face to face, and pledged Him your worship and your need.",
                line: "Now, in the last third of the prayer, you ask. Out of everything a soul could beg for - wealth, healing, relief, rescue - al-Fatiha teaches you to ask first for the one thing every other good depends on: to be shown the way.",
                bridge: nil
            ),
            .verse(
                act: 3, tag: "Guide Us", surah: 1, ayah: 6,
                arabic: "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
                translation: "Guide us to the straight path -",
                reference: "al-Fatiha · 1 : 6",
                reflection: "You already believe. You already pray. So why ask to be guided, every single day? Ibn Kathir puts the question plainly and answers it: the servant needs God's guidance in every moment - to be held on the path already begun, and carried further along it. Al-Tabari splits the word in two: guidance is both being shown the road and being given the strength to actually walk it, against your own pride and distraction and fatigue. The straight path is not information you were handed once; it is a step you take again this morning. Even the faithful must keep asking. Especially them."
            ),
            .verse(
                act: 3, tag: "Whose Footsteps", surah: 1, ayah: 7,
                arabic: "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ",
                translation: "the path of those You have blessed - not of those who earned Your anger, nor of those who went astray.",
                reference: "al-Fatiha · 1 : 7",
                reflection: "And the path is not an abstraction - it has been walked. God names its travelers elsewhere in the Qur'an: the prophets, the truthful, the martyrs, and the righteous. You are asking to be set in their footsteps, and kept from two ways of losing the road: those who knew the truth and refused it out of pride, and those who drifted from it without ever looking back. Knowledge without humility hardens into the first; sincerity without knowledge wanders into the second. The straight path is where the two are married."
            ),
            .response(
                act: 3, replyingTo: "to your plea · 1 : 6-7",
                arabic: "لِعَبْدِي مَا سَأَلَ",
                words: "“This is for My servant - and My servant shall have what he asked.”",
                source: "Hadith Qudsi · Sahih Muslim",
                reflection: "You asked to be shown the way, and the answer came before the asking was done: what you asked for is yours. And what He gives, He now names."
            ),
            .narration(
                act: 3, tag: "The Straight Path",
                source: "The Prophet Muhammad ﷺ · al-Tirmidhi",
                body: "When you ask for the straight path, what exactly are you asking for? The Companions answered in one voice - Ibn Abbas and Ibn Mas'ud said it is the religion of God, it is the Qur'an itself. And the Prophet ﷺ gave the picture. He said God strikes a parable: the straight path is a road walled on both sides, its forbidden doors standing open along the way; and at the head of the road a caller calls, “O people, keep to the path, all of you, and do not swerve.” That caller at the head of the path, he said, is the Book of God. The path you beg for at every prayer is the Book that is calling you onto it.",
                reflection: "This is why the surah has you ask, and does not simply tell. To reach for the straight path is already to be reaching for the Book He left open before you - the one voice that never stops calling you home."
            ),
            .climax(
                act: 3, tag: "The Answer", source: "al-Baqara · 2 : 2",
                arabic: "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًۭى لِّلْمُتَّقِينَ",
                translation: "This is the Book, without doubt, a guidance for the God-conscious.",
                body: "Stop and see what al-Fatiha just did. It ended not with a statement but with a plea: guide us. And then turn the page. The very next words of the Qur'an - the opening of Surat al-Baqara - answer it: “This is the Book, without doubt, a guidance.” You asked to be shown the way, and God's reply is the whole rest of the Book in your hands. The caller on the road and the answer to the prayer are the same voice. Al-Fatiha is the question. The Qur'an is the answer.",
                reflection: "This is the soul of the surah: a prayer God taught you to pray, so that He could answer it - every time you open the Book, every time you rise to pray. The asking and the giving are the same motion."
            ),
            .reflectionPrompt(
                tag: "Return",
                prompt: "Which line will you finally mean?",
                placeholder: "His name, the praise, the turn, or the one request…",
                subline: "You have walked the whole conversation - the praise that is His, the turn where you meet Him, the plea that is yours. The next time you stand to pray, you are not reciting an opening. You are having this exact conversation. Before you go, name the line you most need to mean today.",
                nextLabel: "One last thing"
            ),
            .closing(
                tag: "The Close",
                titleAr: "الْفَاتِحَة",
                essence: "Seven verses God taught you to pray - so that even when you have no words of your own, you always know how to find Him.",
                line: "You have said al-Fatiha all your life. Read it now in its own words, unhurried, as if for the first time - and let the Opening open the Book, the way it opens every prayer."
            ),
        ]
    )
}

#if DEBUG
#Preview("Surah al-Fatiha experience") {
    DeepDiveView(dive: .surahFatiha, onClose: {})
}
#endif
