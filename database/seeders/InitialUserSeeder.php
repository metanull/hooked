<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class InitialUserSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $name = env('HOOKED_INITIAL_USER_NAME');
        $email = env('HOOKED_INITIAL_USER_EMAIL');
        $password = env('HOOKED_INITIAL_USER_PASSWORD');
        $missingVariables = [];

        if (! is_string($name) || $name === '') {
            $missingVariables[] = 'HOOKED_INITIAL_USER_NAME';
        }

        if (! is_string($email) || $email === '') {
            $missingVariables[] = 'HOOKED_INITIAL_USER_EMAIL';
        }

        if (! is_string($password) || $password === '') {
            $missingVariables[] = 'HOOKED_INITIAL_USER_PASSWORD';
        }

        if ($missingVariables !== []) {
            $message = 'Skipping initial user seed. Missing required environment variables: '.implode(', ', $missingVariables);

            if ($this->command !== null) {
                $this->command->warn($message);
            } else {
                echo $message.PHP_EOL;
            }

            return;
        }

        $user = User::query()->updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'password' => $password,
            ],
        );

        if ($user->wasRecentlyCreated) {
            $message = 'Created initial Hooked user for '.$email.'.';
        } else {
            $message = 'Updated initial Hooked user for '.$email.'.';
        }

        if ($this->command !== null) {
            $this->command->info($message);
        } else {
            echo $message.PHP_EOL;
        }
    }
}