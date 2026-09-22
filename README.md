# <img src="public/icon-chef.png" alt="" width="48" align="absmiddle"> Recipe Picker

A recipe discovery app built for the Pennylane take-home challenge. Enter the ingredients you have at home and get a ranked selection of recipes you can make, including what you already have and what you’re missing.

---

## User persona

The target user is a frequent home cook who often has to decide what to make for dinner. They are comfortable cooking; the challenge is quickly narrowing down what to cook from what is available, how much time they have, and what they feel like eating.

I explored this through a small explorative survey of six people who cook at home. Five cooked at least 2-3 times a week, and four said they often or very often struggle with deciding what to cook. Time and visual presentation emerged as useful decision factors.

These findings helped shape how I interpreted the brief and prioritized the prototype. They are directional rather than representative of the wider population.

---



## User stories

The two stories address different parts of the same problem:

- **Find tonight's dinner** focuses on matching the user's ingredients to relevant recipes.
- **Decide what to make** focuses on helping the user evaluate and prioritize those matches.

---



### Find tonight's dinner



#### User story

As a weeknight cook, I want to enter what I have at home, so I can find relevant recipes.

#### Acceptance criteria

**Scenario: The home page explains how to get started**  
Given I have not entered any ingredients  
When I open the app  
Then I see how to list the foods I have at home

**Scenario: I can enter ingredients by name**  
Given I want to find something to cook  
When I enter ingredients separated by commas or new lines  
Then the ingredients are accepted without quantities

**Scenario: Simple ingredient variations are matched**  
Given a recipe requires eggs  
When I enter egg  
Then the recipe is considered a match

**Scenario: Everyday kitchen basics are assumed**  
Given a recipe uses salt, pepper, or water  
When I search with other foods I have  
Then those basics count as already available

**Scenario: Recipe details are easy to understand**  
Given I have found a recipe I am interested in  
When I open the recipe  
Then I see a photo of the dish  
And I see the total, preparation, and cooking time  
And ingredient quantities are shown in grams or millilitres where applicable  
And cup measurements are converted to grams or millilitres  
And teaspoons and tablespoons remain as written

**Scenario: No recipes match an ingredient**  
Given no recipe uses an ingredient I entered  
When I search  
Then I am told that no recipes match

---



### Decide what to make



#### User story

As a weeknight cook, I want to see what I can make with what I have and what I'm missing, so I can quickly decide what to cook.

#### Acceptance criteria

**Scenario: Results help me decide what to cook**  
Given I have entered foods I have at home  
When recipes are shown  
Then I can see how long each recipe takes  
And I can see whether I can cook it now or what I am missing

**Scenario: Recipes I can cook now are prioritized**  
Given some recipes use only ingredients I have  
When results are shown  
Then those recipes appear before recipes with missing ingredients

**Scenario: Recipes missing fewer ingredients come first**  
Given two recipes match foods I have  
And one is missing fewer additional ingredients  
When results are shown  
Then the closer match appears first

**Scenario: Faster recipes are prioritized**  
Given two recipes require the same number of additional ingredients  
And one takes less time  
When results are shown  
Then the faster recipe appears first

**Scenario: Timed recipes are prioritized**  
Given two recipes require the same number of additional ingredients  
And only one has a listed cooking time  
When results are shown  
Then the recipe with a time appears first

**Scenario: Results are limited to a small set**  
Given there are more than nine relevant recipes  
When results are shown  
Then I see no more than nine recipes

**Scenario: Results only include recipes for people**  
Given a recipe is for pet food or treats  
When results are shown  
Then it is not included

**Scenario: I can see what is missing**  
Given I cannot make a recipe with what I have  
When I view the result  
Then I see which ingredients I still need

**Scenario: No recipes are close enough to make**  
Given recipes match a food I entered  
And all matching recipes require more than three additional ingredients  
When results are shown  
Then I am told that the recipes require more than three additional ingredients

---



## Technical

The back-end is built with Ruby on Rails and PostgreSQL, as required by the brief. I chose server-rendered HTML for the interface, as permitted by the FAQ, since I have very limited experience with React.

The provided gzip dump contains recipe titles, ingredients, cooking times, and photos, but no cooking instructions. Cup measurements are converted to grams or millilitres for display.

---

# Problem statement

### _It's dinner time!_ Create an application that helps users find the most relevant recipes that they can prepare with the ingredients that they have at home

## Objective

Deliver a prototype web application to answer the above problem statement.

__✅ Must have's__

- A back-end with Ruby on Rails (If you don't know Ruby on Rails, refer to the FAQ)
- A PostgreSQL relational database
- A well-thought user experience

__🚫 Don'ts__

- Excessive effort in styling
- Features which don't directly answer the above statement
- Over-engineer your prototype

## Deliverable

- The codebase should be pushed on the current GitHub private repository.
- 2 or 3 user stories that address the statement in your repo's `README.md`.
- The application accessible online (a personal server, fly.io or something else). If you can't deploy your app online, refer to the FAQ)
- Submission of the above via [this form](https://forms.gle/siH7Rezuq2V1mUJGA).
- If you're on Mac, make sure your browser has [permission to share the screen](https://support.apple.com/en-al/guide/mac-help/mchld6aa7d23/mac).


## Data

Please start from the following dataset to perform the assignment:
[english-language recipes](https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz) scraped from www.allrecipes.com with [recipe-scrapers](https://github.com/hhursev/recipe-scrapers)

Download it with this command if the above link doesn't work:
```sh textWrap
wget https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz && gzip -dc recipes-en.json.gz > recipes-en.json
```

## FAQ

<details>
<summary><i>I'm a back-end developer or don't know React, what do I do?</i></summary>

Just make the simplest UI, style isn't important and server rendered HTML pages will do!
</details>

<details>
<summary><i>Can I have a time extension for the test?</i></summary>

No worries, we know that unforeseen events happen, simply reach out to the recruiter you've been
talking with to discuss this.
</details>

<details>
<summary><i>Can I transform the dataset before seeding it in the DB</i></summary>

Absolutely, feel free to post-process the dataset as needed to fit your needs.
</details>

<details>
<summary><i>Should I rather implement option X or option Y</i></summary>

That decision is up to you and part of the challenge. Please document your choice
to be able to explain your reflexion and choice to your interviewer for the
challenge debrief.
</details>

<details>
<summary><i>Do I really have to deploy the application online?</i></summary>
Deploying the application does ensure a smooth interview experience by allowing interviewers to test your code live. However, you should not overinvest time (or money) on this if you really can't figure it. You can alternatively provide demo videos as a worst case option, as interviewers won't checkout and run the application to cover for missing demo or online version. In case you don't have an online application, please make sure everything is working smoothly
locally before your debrief interview.
  
</details>

<details>
<summary><i>I don't know <b>Ruby on Rails</b></i></summary>

That probably means you're applying for a managerial position, so it's fine to
pick another language of your choice to perform this task.
</details>

<details>


<summary><i>Can I use AI tools?</b></i></summary>

You are free to use AI tools to assist you in completing this case study. To maintain transparency, please document which AI tools you used during the assignment.

For each tool, briefly explain:
- The main tasks or problems for which you used it.
- How you validated and refined any AI-generated code.

Note: While AI can be a valuable assistant, interviewers will assess your ability to understand the entire codebase, explain key technical choices, and effectively answer technical questions about improvements. We expect candidates to use AI as a supportive tool rather than having it generate the complete solution. AI should supplement your coding process, not replace your critical thinking and hands-on development work.
</details>
