<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Task extends Model
{
    use HasFactory;

    /**
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'directory',
        'label',
        'scheduled_task_path',
        'type',
        'active',
        'webhook_repository_pattern',
        'webhook_branch_pattern',
    ];

    /**
     * @var array<string, string>
     */
    protected $casts = [
        'active' => 'boolean',
    ];

    public function deployments(): HasMany
    {
        return $this->hasMany(Deployment::class);
    }
}