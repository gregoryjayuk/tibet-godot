# The conversations' own lines: the language check

_What this is: every line the story's conversations say that is not already a phrasebook line (M2 sprint 1, step 2), with who says it, where and when, and the English the player reads now; the game shows it in English alone until it is written in its script here and checked. How to use it: write the line in Tibetan (or Chinese) in its cell, put ✓ in its Check cell, then `python3 tools/culture/conversation_lines.py --apply` writes it into its conversation (data/conversations/), and the game shows it in its script with the English under it. Rebuilt by the same script without --apply; the two cells are kept. The phrasebook's lines the conversations use are checked in [bark-lines-check.md](bark-lines-check.md)._

| # | ID | English in the game | Who | Where in the story | Tibetan (or Chinese), to write | Check |
|---|---|---|---|---|---|---|
| 1 | CV-020 | Eat, Dorje, eat. And the resident's arrow? What did it say? | Ama Yudrön, the chang house's widow | m2_order (line 1) |  |  |
| 2 | CV-021 | Animals, men and fodder, for the resident's officers, at the new moon. | Jiang Deshun, the post's interpreter | m2_order (line 2) |  |  |
| 3 | CV-022 | How many animals? | Ama Yudrön, the chang house's widow | m2_order (line 3) |  |  |
| 4 | CV-023 | It does not say how many. The castle will say. | Jiang Deshun, the post's interpreter | m2_order (line 4) |  |  |
| 5 | CV-026 | Auntie! How many animals did the arrow want? | a soldier of the post | m2_soldiers (line 1), in Sichuanese: write it in Chinese |  |  |
| 6 | CV-027 | Two hundred, they say, and every one of them strong. | Ama Yudrön, the chang house's widow | m2_soldiers (line 2), in Sichuanese: write it in Chinese |  |  |
| 7 | CV-028 | Two hundred! Then the post can carry its own fodder. | another soldier of the post | m2_soldiers (line 3), in Sichuanese: write it in Chinese |  |  |
| 8 | CV-010 | Drink, drink. It's hot. | Ama Yudrön, the chang house's widow | story_lines (the chang house, pouring a guest's bowl) |  |  |
| 9 | CV-040 | Hold the dog! | player | story_lines (the headman's yard gate, its mastiff barking (chapter 02, 5.1: the visitor's call, ཁྱི་ཟུངས)) |  |  |
| 10 | CV-041 | He's held. Come in. | headman groom | story_lines (the headman's yard, holding the mastiff by its collar) |  |  |
| 11 | CV-042 | Please, sit on the lower bench. | yangchen drolma | story_lines (the headman's reception room, the guest at the headman's bench (chapter 04, 4.1: sit on the lower bench, never the headman's)) |  |  |
| 12 | CV-001 | We will speak of this indoors, not here. Go up and rest; the child will show you the roofs at dusk. Tomorrow I must ride out to the caravan ground: you will carry the last offers between my rooms. | Achak Dolkar, the hostess of Dechen-tsang | m1_letter (open2) |  |  |
| 13 | CV-002 | You did well to bring this to me yourself. Say nothing of it in the town. Nothing. Tomorrow I must ride out to the caravan ground: you will carry the last offers between my rooms. | Achak Dolkar, the hostess of Dechen-tsang | m1_letter (shut2) |  |  |
| 14 | CV-003 | Then come to the house. Tea first; the rest after. | Achak Dolkar, the hostess of Dechen-tsang | m1_letter (wait1) |  |  |
| 15 | CV-024 | You heard him. Sixty animals from Shöl, the castle will ask. Sixty. A house that trades can bear sixty. | Ama Yudrön, the chang house's widow | m2_yudron (a) |  |  |
| 16 | CV-025 | Dechen-tsang can. Half the town owes Dechen-tsang, and the castle owes it most, though nobody says so. Gönpo the coracle man owes it a hide. I owe it my roof. | Ama Yudrön, the chang house's widow | m2_yudron (b) |  |  |
