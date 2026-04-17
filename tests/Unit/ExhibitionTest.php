<?php

namespace Tests\Unit;

use App\Models\Exhibition;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class ExhibitionTest extends TestCase
{
    public function test_validation_rules_accept_a_valid_exhibition_payload(): void
    {
        $validator = Validator::make([
            'name' => 'arts_in_dialogue',
            'language_id' => 'de',
            'status' => 'Installed',
            'api_env' => ['APP_NAME' => 'Dialogue'],
            'client_env' => ['VITE_APP_NAME' => 'Dialogue'],
            'synced_at' => now()->toIso8601String(),
        ], Exhibition::validationRules());

        $this->assertFalse($validator->fails());
    }

    public function test_validation_rules_reject_invalid_name_and_language_id_values(): void
    {
        $validator = Validator::make([
            'name' => 'Invalid Exhibition',
            'language_id' => 'english',
            'status' => 'Installed',
        ], Exhibition::validationRules());

        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('name', $validator->errors()->toArray());
        $this->assertArrayHasKey('language_id', $validator->errors()->toArray());
    }
}