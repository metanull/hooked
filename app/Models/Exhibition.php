<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Exhibition extends Model
{
    use HasFactory;

    public const NAME_PATTERN = '/^[a-z][a-z0-9_-]+[a-z]$/';

    public const LANGUAGE_ID_PATTERN = '/^[a-z]{2}$/';

    /**
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'language_id',
        'status',
        'api_env',
        'client_env',
        'synced_at',
    ];

    /**
     * @var array<string, string>
     */
    protected $casts = [
        'api_env' => 'array',
        'client_env' => 'array',
        'synced_at' => 'datetime',
    ];

    /**
     * @return array<string, array<int, string>>
     */
    public static function validationRules(): array
    {
        return [
            'name' => ['required', 'regex:'.self::NAME_PATTERN],
            'language_id' => ['required', 'regex:'.self::LANGUAGE_ID_PATTERN],
            'status' => ['required', 'string'],
            'api_env' => ['nullable', 'array'],
            'client_env' => ['nullable', 'array'],
            'synced_at' => ['nullable', 'date'],
        ];
    }
}