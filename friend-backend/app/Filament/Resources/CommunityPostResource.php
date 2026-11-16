<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityPostResource\Pages;
use App\Models\CommunityPost;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

class CommunityPostResource extends Resource
{
    protected static ?string $model = CommunityPost::class;
    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';
    protected static ?string $navigationGroup = 'Community';
    protected static ?string $navigationLabel = 'Posts';
    protected static ?int $navigationSort = 50;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('user.name')->label('Author')->disabled(),
            Forms\Components\TextInput::make('channel.name')->label('Channel')->disabled(),
            Forms\Components\Textarea::make('body_md')->label('Body (markdown)')->disabled()->rows(6),
            Forms\Components\TextInput::make('status')->disabled(),
            Forms\Components\TextInput::make('reply_to_id')->label('Reply to')->disabled(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('user.name')->label('Author')->searchable(),
                Tables\Columns\TextColumn::make('channel.name')->label('Channel'),
                Tables\Columns\TextColumn::make('body_md')->label('Body')->limit(60)->searchable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'published' => 'success',
                        'flagged'   => 'warning',
                        'removed'   => 'danger',
                        default     => 'gray',
                    }),
                Tables\Columns\TextColumn::make('flag_count')->counts('flags')->label('Flags')->alignCenter(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(['published' => 'Published', 'flagged' => 'Flagged', 'removed' => 'Removed']),
                Tables\Filters\SelectFilter::make('channel_id')->relationship('channel', 'name')->label('Channel'),
            ])
            ->actions([
                Tables\Actions\Action::make('remove')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->form([Forms\Components\Textarea::make('reason')->required()])
                    ->action(function (CommunityPost $record, array $data) {
                        $record->update(['status' => 'removed', 'moderation_reason' => $data['reason'], 'moderated_by' => Auth::id(), 'moderated_at' => now()]);
                        Notification::make()->title('Post removed')->success()->send();
                    }),
                Tables\Actions\Action::make('clear_flags')
                    ->icon('heroicon-o-flag')
                    ->color('gray')
                    ->visible(fn (CommunityPost $r) => $r->status === 'flagged')
                    ->action(fn (CommunityPost $record) => $record->update(['status' => 'published']) + $record->flags()->delete())
                    ->after(fn (CommunityPost $record) => Notification::make()->title('Flags cleared')->info()->send()),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCommunityPosts::route('/'),
        ];
    }
}