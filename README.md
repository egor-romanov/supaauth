# supaauth

This is a simple project that demonstrates how to use supabase-swift to authenticate users with Supabase in a SwiftUI app natively. 

## Supabase features used in this project

- Apple Sign In and Supabase Auth
- Edge Functions with AI models for embedding generation

The app enables users to log in and save their notes. The edge function generates embeddings for the notes and saves them in the database. Later, users can search for notes using vector similarity search.

## How to run this project

1. Clone the project
2. Install the dependencies
3. Create a new Supabase project, and enable Apple auth provider in auth settings
4. Install supabase CLI and login to your account
5. Run migrations from the `supabase/migrations` folder
6. Deploy edge functions from the `supabase/functions` folder
7. Update the `supabaseUrl` and `supabaseKey` in the `AuthManager.swift` file
8. Run the project
9. Have fun!

## Acknowledgements

This project is inspired by the [Jason Dubon](https://www.youtube.com/channel/UCpxYdczRtlaP7HcZDGaWVWg) guide on how to use Supabase with SwiftUI to implement native authentication and made for London Supabase 04.2024 meetup.
