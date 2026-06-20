<?php

namespace App\Http\Controllers\Settings;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AiSettingsController extends Controller
{
    public function update(Request $request)
    {
        $validated = $request->validate([
            'favorite_ia' => 'nullable|string',

            'profile' => 'array',
            'shortcuts' => 'array',
            'shortcuts.*.command' => 'nullable|string',
            'shortcuts.*.instruction' => 'nullable|string',
        ]);
        $request->user()->update(['shortcut' => $validated['shortcuts']]);
        $request->user()->update(['favorite_ia' => $validated['favorite_ia']]);
        foreach ($validated['profile'] as $setting => $value) {
            $request->user()->aiSettings()->updateOrCreate(
                ['setting' => $setting],
                ['value' => $value]
            );
        }

        return back();
    }
}
