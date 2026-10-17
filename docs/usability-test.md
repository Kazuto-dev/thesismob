# Usability test kit

A ready-to-run moderated test of BuildQuantify with five to eight people,
about 40 minutes each. It checks whether the people the app is for can
estimate, build a project and share it without help, and it gives a
System Usability Scale (SUS) score to compare releases against.

## Who to recruit

Aim for five people in each group you care about; five find most of the
problems a group runs into.

| Group | Who | Why |
| --- | --- | --- |
| Owners | Someone building or renovating a house in the next year, no construction training | The largest group; tests plain language and guidance |
| Foremen | A *kapatas* or mason who orders materials | Tests whether quantities and units match how they buy |
| Estimators | A junior engineer or quantity surveyor who prepares bids | Tests the bill of quantities, budget and exports |

Mix phone and laptop users, and include at least two people who prefer
Filipino. Pay or thank participants with a gift worth about ₱500.

## Before the session

- Use the release build on the participant's own phone or a laptop, signed
  out and with no saved data (a private window works).
- Have a stopwatch and the observation sheet below.
- Read the consent script and get a yes before recording anything.

> "We are testing the app, not you. There are no wrong answers. Please
> think aloud: say what you are looking for and what you expect to
> happen. I can't help during the tasks, but I'll answer your questions
> at the end. May I record the screen and audio? Only the team will see
> it, and you can stop at any time."

## Tasks

Read each task aloud and hand over a printed copy. Don't name buttons or
screens. Stop a task after five minutes and note it as a failure.

1. **A wall.** "You are building a 10 m by 3 m wall of 4-inch hollow
   blocks. How many blocks do you need, and how much will they cost?"
   *Success:* reads 394 blocks and the total.
2. **Units.** "Your foreman measured the bedroom as 12 by 10 feet. Work
   out the floor tiles for it." *Success:* uses feet, or converts
   correctly; notes whether the unit hint or the "did you mean" message
   helped.
3. **A project.** "Start a project for the Santos house and add the wall
   and the tiles to it." *Success:* both items are in one project.
4. **Change an item.** "The wall is actually 4 m tall. Fix it in the
   project." *Success:* one wall item, now 4 m; no duplicate.
5. **Your supplier's price.** "Your hardware sells cement at ₱255 a bag.
   Make the project use that price." *Success:* the project total
   changes.
6. **The budget.** "You will hire a contractor. How much should you
   expect to pay in total, with their profit and VAT?" *Success:* switches
   to the contractor budget and reads the total.
7. **Share it.** "Send the bill of quantities to your engineer."
   *Success:* downloads the PDF or saves to Google Sheets.
8. **Plan a house** (owners only). "You are planning a new two-bedroom
   house. What would you estimate next?" *Success:* finds the house
   checklist and names the next item.

## What to record for each task

| Measure | How |
| --- | --- |
| Completed | Yes, with help, or no |
| Time | From reading the task to success or giving up |
| Errors | Wrong screen, wrong unit, wrong number, retries |
| Quotes | Words of confusion or delight, verbatim |
| Severity of each problem | 1 cosmetic · 2 minor · 3 major (slowed them a lot) · 4 blocker |

## System Usability Scale

After the tasks, ask the ten statements below on a 1–5 scale (1 strongly
disagree, 5 strongly agree). Offer the Filipino wording to anyone who
prefers it.

| # | English | Filipino |
| --- | --- | --- |
| 1 | I think that I would like to use this app frequently. | Sa tingin ko, gusto kong gamitin nang madalas ang app na ito. |
| 2 | I found the app unnecessarily complex. | Masyadong komplikado ang app nang hindi kailangan. |
| 3 | I thought the app was easy to use. | Madaling gamitin ang app. |
| 4 | I think that I would need the support of a technical person to be able to use this app. | Kailangan ko ng tulong ng taong marunong para magamit ang app na ito. |
| 5 | I found the various functions in this app were well integrated. | Magkakaugnay nang maayos ang iba't ibang bahagi ng app. |
| 6 | I thought there was too much inconsistency in this app. | Maraming hindi magkakatugma sa app na ito. |
| 7 | I would imagine that most people would learn to use this app very quickly. | Sa tingin ko, mabilis matututunan ng karamihan ang app na ito. |
| 8 | I found the app very cumbersome to use. | Napakahirap at nakakaabalang gamitin ang app. |
| 9 | I felt very confident using the app. | Kampante ako habang ginagamit ang app. |
| 10 | I needed to learn a lot of things before I could get going with this app. | Marami akong kinailangang matutunan bago ko nagamit ang app. |

**Scoring.** For odd items subtract 1 from the answer; for even items
subtract the answer from 5. Add the ten results and multiply by 2.5, for
a score from 0 to 100. Average the participants.

| Score | Reading |
| --- | --- |
| Above 80 | Excellent; people would recommend it |
| 68 | Average across products studied by Sauro (2011) |
| Below 51 | Serious problems to fix before release |

Then ask three open questions:

1. "What was the hardest part?"
2. "What would you need before trusting these numbers for buying?"
3. "What would you add or change?"

## After the sessions

1. List every problem with its severity and how many people hit it.
2. Fix blockers and majors seen by two or more people first.
3. Record the SUS average and task success rates with the app version, so
   the next round can be compared.

## References

- Brooke, J. (1996). SUS: a "quick and dirty" usability scale. In
  *Usability Evaluation in Industry*. Taylor & Francis.
- Sauro, J. (2011). *A Practical Guide to the System Usability Scale*.
  Measuring Usability LLC.
- Nielsen, J. (2000). *Why You Only Need to Test with 5 Users*. Nielsen
  Norman Group.
